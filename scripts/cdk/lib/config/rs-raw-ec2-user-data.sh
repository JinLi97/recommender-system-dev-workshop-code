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


AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)

# code
echo "==== setup code ======"
export HOME=/home/ec2-user

#https://git-codecommit.ap-northeast-1.amazonaws.com/v1/repos/gcrRsDevWorkshopRepo

url_suffix='com'
if [[ AWS_REGION =~ ^cn.* ]];then
    url_suffix='com.cn'
fi 
repo_name="https://git-codecommit.$AWS_REGION.amazonaws.${url_suffix}/v1/repos/recommender-system-dev-workshop-code"
echo $repo_name

echo "run git config --global"
git config --global user.name "rs-dev-workshop"
git config --global user.email "rs-dev-workshop@example.com"
git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true
echo "git config --global --list"
git config --global --list
echo ""


echo "==== config AWS ENV ======"
# config AWS ENV
sudo -u ec2-user -i <<EOS
echo "set default.region"
aws configure set default.region ${AWS_REGION}
aws configure get default.region
echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a /home/ec2-user/.bash_profile
echo "export AWS_REGION=${AWS_REGION}" | tee -a /home/ec2-user/.bash_profile
echo "export REGION=${AWS_REGION}" | tee -a /home/ec2-user/.bash_profile

mkdir /home/ec2-user/environment
cd /home/ec2-user/environment
wget https://github.com/gcr-solutions/recommender-system-dev-workshop-code/archive/refs/heads/main.zip
unzip main.zip

echo "git clone ${repo_name}"
git clone ${repo_name}

mv ./recommender-system-dev-workshop-code-main/* ./recommender-system-dev-workshop-code/

rm -rf recommender-system-dev-workshop-code-main
cd ./recommender-system-dev-workshop-code/
git add . && git commit -m 'first commit' && git push

EOS

# httpd
yum install -y httpd
systemctl start httpd
systemctl enable httpd

echo "<h1>Hello World from AWS EC2 $(hostname -f)</h1><br><hr><h2>Start Time: $(date -'u' )</h2>" > /var/www/html/index.html

echo "End time: $(date '-u')"
exit 0
