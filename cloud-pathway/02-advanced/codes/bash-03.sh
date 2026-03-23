aws s3api select-object-content \
    --bucket my-bucket \
    --key data.csv \
    --expression "SELECT * FROM s3object s WHERE s.age > 25" \
    --expression-type SQL \
    --input-serialization '{"CSV": {}}' \
    --output-serialization '{"CSV": {}}' \
    output.csv