import boto3
import socket
import subprocess
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

    def test_ssh_listening(self):
        instances = self.get_instances()
        for instance in instances:
            self.assertTrue(self.can_connect_to_port(instance.public_ip_address, 22))

    def test_syslog_listening(self):
        instances = self.get_instances()
        logging_port = self.get_logging_port()
        for instance in instances:
            self.assertTrue(self.can_connect_to_port(instance.public_ip_address, logging_port))

    def test_syslog_through_lb(self):
        logging_host = self.get_terraform_output('logging_host')
        logging_port = self.get_logging_port()
        self.assertTrue(self.can_connect_to_port(logging_host, logging_port))


if __name__ == '__main__':
    unittest.main()
