import boto3
from contextlib import contextmanager
import logging
from logging import handlers
import paramiko
import socket
import subprocess
import time
import unittest
import warnings


class TestLogForwarding(unittest.TestCase):

    def can_connect_to_port(self, host, port):
        # https://stackoverflow.com/a/20541919
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(2.0)
        result = s.connect_ex((host, port))
        s.close()
        return result == 0

    def get_terraform_output(self, name):
        cmd = ['terraform', 'output', name]
        result = subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return result.stdout.decode('utf-8').strip()

    def get_instances(self):
        # workaround for https://github.com/boto/boto3/issues/454
        warnings.simplefilter('ignore', ResourceWarning)

        vpc_id = self.get_terraform_output('vpc_id')
        ec2 = boto3.resource('ec2')
        instances = ec2.instances.filter(Filters=[
                {'Name': 'instance-state-name', 'Values': ['running']},
                {'Name': 'vpc-id', 'Values': [vpc_id]}
        ])
        self.assertGreaterEqual(len(list(instances)), 1)
        return instances

    def get_logging_port(self):
        return int(self.get_terraform_output('logging_port'))

    def send_syslog(self, host, port, msg):
        logger = logging.getLogger()
        logger.setLevel(logging.DEBUG)
        # use TCP; requires Python 3.2+
        handler = handlers.SysLogHandler(address=(host, port), socktype=socket.SOCK_STREAM)
        logger.addHandler(handler)

        # include the current time so that it doesn't get mistaken for previous test runs
        msg = "test message from Python unittest, at {0}".format(int(time.time()))
        logger.info(msg)

    @contextmanager
    def ssh_client(self, host, ssh_user):
        ssh = paramiko.SSHClient()
        # https://stackoverflow.com/a/17732926/358804
        ssh.load_system_host_keys()
        ssh.connect(host, username=ssh_user, look_for_keys=False)
        try:
            yield ssh
        finally:
            ssh.close()

    @contextmanager
    def fluentd_log(self, host, ssh_user):
        with self.ssh_client(host, ssh_user) as ssh:
            # https://stackoverflow.com/a/1597750/358804
            sftp = ssh.open_sftp()
            try:
                remote_file = sftp.open('/var/log/td-agent/td-agent.log')
                try:
                    yield remote_file
                finally:
                    remote_file.close()
            finally:
                sftp.close()

    def received_syslog(self, host, ssh_user, msg):
        with self.fluentd_log(host, ssh_user) as f:
            for line in f:
                if msg in line:
                    return True
        return False

    def test_ssh_listening(self):
        instances = self.get_instances()
        for instance in instances:
            self.assertTrue(self.can_connect_to_port(instance.public_ip_address, 22))

    def test_syslog_listening(self):
        instances = self.get_instances()
        logging_port = self.get_logging_port()
        for instance in instances:
            self.assertTrue(self.can_connect_to_port(instance.public_ip_address, logging_port))

    def test_syslog_listening_through_lb(self):
        logging_host = self.get_terraform_output('logging_host')
        logging_port = self.get_logging_port()
        self.assertTrue(self.can_connect_to_port(logging_host, logging_port))

    def test_syslog_through_lb(self):
        logging_host = self.get_terraform_output('logging_host')
        logging_port = self.get_logging_port()

        # include the current time so that it doesn't get mistaken for previous test runs
        msg = "test message from Python unittest, at {0}".format(int(time.time()))
        self.send_syslog(logging_host, logging_port, msg)

        # could have gone to any of the fluentd instances, so check all of them
        instances = self.get_instances()
        found = False
        for instance in instances:
            if self.received_syslog(instance.public_ip_address, 'ubuntu', msg):
                found = True
                break

        self.assertTrue(found)


if __name__ == '__main__':
    unittest.main()
