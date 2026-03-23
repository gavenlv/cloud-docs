for循环：
for i in 1 2 3 4 5; do
    echo $i
done

for i in {1..10}; do
    echo $i
done

for file in *.txt; do
    echo "Processing $file"
done

while循环：
count=0
while [ $count -lt 10 ]; do
    echo $count
    count=$((count + 1))
done

until循环：
until [ $count -ge 10 ]; do
    echo $count
    count=$((count + 1))
done