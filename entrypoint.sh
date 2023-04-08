#!/bin/sh

github_token="$INPUT_TOKEN"
port_client_id="$INPUT_PORTCLIENTID"
port_client_secret="$INPUT_PORTCLIENTSECRET"
port_run_id="$INPUT_RUNID"
blueprint_identifier="$INPUT_BLUEPRINTIDENTIFIER"
repository_name="$INPUT_REPOSITORYNAME"
org_name="$INPUT_ORGANIZATIONNAME"
cookie_cutter_template="$INPUT_COOKIECUTTERTEMPLATE"
port_user_inputs="$INPUT_PORTUSERINPUTS"

access_token=$(curl -s --location --request POST 'https://api.getport.io/v1/auth/access_token' --header 'Content-Type: application/json' --data-raw "{
    \"clientId\": \"$port_client_id\",
    \"clientSecret\": \"$port_client_secret\"
}" | jq -r '.accessToken')

curl --location "https://api.getport.io/v1/actions/runs/$port_run_id/logs" \
  --header "Authorization: Bearer $access_token" \
  --header "Content-Type: application/json" \
  --data "{
    \"message\": \"Creating a new repository: $repository_name 🏃\"
  }"

# Create a new repostiory in github
curl -i -H "Authorization: token $github_token" \
    -d "{ \
        \"name\": \"$repository_name\", \"private\": true
      }" \
    https://api.github.com/orgs/$org_name/repos

curl --location "https://api.getport.io/v1/actions/runs/$port_run_id/logs" \
  --header "Authorization: Bearer $access_token" \
  --header "Content-Type: application/json" \
  --data "{
    \"message\": \"Created a new repository at https://github.com/$org_name/$repository_name ✅\"
  }"

curl --location "https://api.getport.io/v1/actions/runs/$port_run_id/logs" \
  --header "Authorization: Bearer $access_token" \
  --header "Content-Type: application/json" \
  --data "{
    \"message\": \"Starting templating with cookiecutter 🍪\"
  }"

echo "$port_user_inputs" | grep -o "cookie_cutter[^ ]*" | sed 's/cookie_cutter//g' >> cookiecutter.json

cookiecutter $cookie_cutter_template --no-input

# Switching directory to the newly created directory

cd "$(ls -td -- */ | head -n 1)"

git init
git remote add origin https://oauth2:$github_token@github.com/$org_name/$repository_name.git
git config user.name "GitHub Actions Bot"
git config user.email "github-actions[bot]@users.noreply.github.com"
git add .
git commit -m "Initial commit after scaffolding"
git push

curl --location "https://api.getport.io/v1/actions/runs/$port_run_id/logs" \
  --header "Authorization: Bearer $access_token" \
  --header "Content-Type: application/json" \
  --data "{
    \"message\": \"Starting templating with cookiecutter 🍪\"
  }"



