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

    def test_ssh_to_test_instance(self):
        # workaround for https://github.com/boto/boto3/issues/454
        warnings.simplefilter('ignore', ResourceWarning)

        vpc_id = self.get_terraform_output('vpc_id')
        ec2 = boto3.resource('ec2')
        instances = ec2.instances.filter(Filters=[
                {'Name': 'instance-state-name', 'Values': ['running']},
                {'Name': 'vpc-id', 'Values': [vpc_id]}
        ])

        self.assertEqual(len(list(instances)), 1)
        for instance in instances:
            self.assertTrue(self.can_connect_to_port(instance.public_ip_address, 22))


if __name__ == '__main__':
    unittest.main()
