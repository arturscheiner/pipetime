#!/bin/bash
# usar
# ./pipetime.sh "endpoint" "apikey" "method"
# if you want to send a payload together, please fulfill the payload.json file with the json data.

# ENDPOINT="https://test.godigibee.io/pipeline/demo/v1/elastic-pipeline-sample?cep=07500-000"
# APIKEY="xxxxxxxxxxxxxxxxxxxxxxxxxxx"

ENDPOINT=$1
APIKEY=$2
METHOD=$3

if [[ -f payload.json ]]; then
  PAYLOAD=$(cat payload.json)
else
  PAYLOAD=""
fi

echo "Executing..."
echo "Endpoint: $ENDPOINT"
echo "ApiKey: $APIKEY"
echo "Payload:"
echo $(echo $PAYLOAD)

DOMAIN=$(echo $ENDPOINT | awk -F/ '{print $3}')
PIPELINE=$(echo $ENDPOINT | awk -F/ '{print $7}' | awk -F"?" '{print $1}')
VERSION=$( echo $ENDPOINT | awk -F/ '{print $6}')

rm -Rf ./output.sh

queryExec() {
    curl -w @- -o result.json -s "$ENDPOINT" \
        -X $METHOD \
        -H 'content-type: application/json' \
        -H 'accept: */*' \
        -H 'accept-language: pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7' \
        -H "apikey: $APIKEY" \
        --data-raw $"$PAYLOAD" <<EOF
#!/bin/bash\n
size_download=%{size_download}\n
size_header=%{size_header}\n
size_request=%{size_request}\n
size_upload=%{size_upload}\n
speed_download=%{speed_download}\n
speed_upload=%{speed_upload}\n
time_namelookup=%{time_namelookup}\n
time_connect=%{time_connect}\n
time_appconnect=%{time_appconnect}\n
time_pretransfer=%{time_pretransfer}\n
time_starttransfer=%{time_starttransfer}\n
#time_digibee=\$(echo \$time_starttransfer-\$time_pretransfer | bc)\n
time_digibee=\$(echo \$time_starttransfer \$time_pretransfer | awk '{printf "%f", \$1 - \$2}')\n
time_total=%{time_total}\n
echo "Result:"\n
cat result.json\n
echo\n\n
echo "\nSize:"\n
echo "download: \$size_download"\n
echo "header: \$size_header"\n
echo "request: \$size_request"\n
echo "upload: \$size_upload"\n
echo\n
echo "Speed:"\n
echo "download: \$speed_download"\n
echo "upload: \$speed_upload"\n
echo\n
echo "Time:"\n
echo "1 - namelookup:  \$time_namelookup - The time in seconds it took to resolve the $DOMAIN."\n
echo "2 - connect:  \$time_connect - The time in seconds, it took from the start until the TCP connect to the $DOMAIN."\n
echo "3 - appconnect:  \$time_appconnect - The time in seconds, it took from the start until the connect/handshake to the remote host was completed."\n
echo "4 - pretransfer:  \$time_pretransfer - The time in seconds, it took from the start until the file transfer was just about to begin."\n
echo "5 - digibee: \$time_digibee - The time in seconds, it took inside Digibee platform pipeline $PIPELINE $VERSION."\n
echo "6 - starttransfer: \$time_starttransfer - The time in seconds, it took from the start until the first byte was just about to be transferred from $PIPELINE $VERSION."\n
echo "7 - total:  %{time_total} - The total time in seconds, that the full operation lasted."\n
echo\n
EOF
}

runExec() {
    queryExec > output.sh
    chmod +x ./output.sh
    ./output.sh
}

runExec