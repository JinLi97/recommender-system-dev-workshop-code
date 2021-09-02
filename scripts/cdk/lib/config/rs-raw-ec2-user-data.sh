set -e

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Start time: $(date '-u')"

sudo su
yum update -y

# docker
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user

# software
yum install git -y
yum install jq -y

# httpd
yum install -y httpd

systemctl start httpd
systemctl enable httpd

echo "<h1>Hello World from AWS EC2 $(hostname -f)</h1><br><hr><h2>Start Time: $(date -'u' )</h2>" > /var/www/html/index.html

# config AWS ENV
AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
sudo -u ec2-user -i <<EOS
echo "set default.region"
aws configure set default.region ${AWS_REGION}
aws configure get default.region
echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a /home/ec2-user/.bash_profile
echo "export AWS_REGION=${AWS_REGION}" | tee -a /home/ec2-user/.bash_profile
echo "export REGION=${AWS_REGION}" | tee -a /home/ec2-user/.bash_profile
EOS
echo "End time: $(date '-u')"
exit 0

