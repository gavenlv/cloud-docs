# 备份数据卷
docker run --rm \
  -v my-volume:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/my-volume-backup.tar.gz /data

# 恢复数据卷
docker run --rm \
  -v my-volume:/data \
  -v $(pwd):/backup \
  alpine sh -c "cd /data && tar xzf /backup/my-volume-backup.tar.gz --strip 1"

# 备份所有数据卷
for volume in $(docker volume ls -q); do
  docker run --rm \
    -v $volume:/data \
    -v $(pwd):/backup \
    alpine tar czf /backup/$volume-backup.tar.gz /data
done

# 恢复所有数据卷
for backup in $(ls backup/*-backup.tar.gz); do
  volume=$(basename $backup -backup.tar.gz)
  docker run --rm \
    -v $volume:/data \
    -v $(pwd):/backup \
    alpine sh -c "cd /data && tar xzf /backup/$volume-backup.tar.gz --strip 1"
done