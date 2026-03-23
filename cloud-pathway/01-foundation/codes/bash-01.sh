aws ec2 run-instances \
    --image-id ami-0c55b159cbfafe1f0 \
    --instance-type t3.medium \
    --key-name my-key-pair \
    --security-group-ids sg-12345678 \
    --subnet-id subnet-12345678 \
    --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":50,"VolumeType":"gp3"}}]'