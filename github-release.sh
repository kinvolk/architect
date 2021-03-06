SHA=$1
PERSONAL_ACCESS_TOKEN=$2

SHORT_SHA=$(echo ${SHA} | head -c 7)
DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "Creating Tag"
tag_output=$(curl \
    --request POST \
    --header "Authorization: token $PERSONAL_ACCESS_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{
        \"tag\": \"${SHA}\",
        \"message\": \"automated tag for ${SHORT_SHA}\",
        \"object\": \"${SHA}\",
        \"type\": \"commit\",
        \"tagger\": {
            \"name\": \"taylorbot\",
            \"email\": \"dev@giantswarm.io\",
            \"date\": \"${DATE}\"
        }
    }" \
    https://api.github.com/repos/giantswarm/architect/git/tags
)
echo $tag_output | jq

echo "Creating GitHub Release"
release_output=$(curl \
    --request POST \
    --header "Authorization: token ${PERSONAL_ACCESS_TOKEN}" \
    --header "Content-Type: application/json" \
    --data "{
        \"tag_name\": \"${SHORT_SHA}\",
        \"name\": \"${SHORT_SHA}\",
        \"body\": \"Automated release for ${SHORT_SHA}.\",
        \"draft\": false,
        \"prerelease\": false
    }" \
    https://api.github.com/repos/giantswarm/architect/releases
)
echo $release_output | jq

# fetch the release id for the upload
RELEASE_ID=$(echo $release_output | jq '.id')

echo "Upload binary to GitHub Release"
upload_output=$(curl \
    --header "Authorization: token ${PERSONAL_ACCESS_TOKEN}" \
    --header "Content-Type: application/octet-stream" \
    --data-binary @architect \
    https://uploads.github.com/repos/giantswarm/architect/releases/${RELEASE_ID}/assets?name=architect
)
echo $upload_output | jq

echo "Done!"
