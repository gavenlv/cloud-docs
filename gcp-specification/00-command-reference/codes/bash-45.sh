# 查看实例串口输出
gcloud compute instances get-serial-port-output instance-name --zone=us-central1-a

# 查看Cloud Run日志
gcloud run services logs read my-service --region=us-central1

# 查看Cloud Build日志
gcloud builds log BUILD_ID