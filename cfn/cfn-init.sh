#!/bin/bash

set -e
echo $AWS_ACCOUNT_ID
STACK_NAME=""
TEMPLATE_FILE=""
PARAMS_FILE=""
TAGS_FILE=""
ENV=""
AWS_ACCOUNT_ID=""

print_usage() {
  echo "Usage: $0 --stack-name <name> --template-file <path> --params-file <path> [--tags-file <path>]"
  echo ""
  echo "Options:"
  echo "  --stack-name        CloudFormation stack name (mandatory)"
  echo "  --template-file     CloudFormation template file path (mandatory)"
  echo "  --params-file       JSON file with parameter overrides (mandatory)"
  echo "  --env               Environment name (mandatory)"
  echo "  --tags-file         Text file with tags in Key=Value format (optional)"
  echo "  -h, --help          Show this help message"
}

# Parse CLI arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --stack-name)
      STACK_NAME="$2"
      shift 2
      ;;
    --template-file)
      TEMPLATE_FILE="$2"
      shift 2
      ;;
    --params-file)
      PARAMS_FILE="$2"
      shift 2
      ;;
    --account)
      AWS_ACCOUNT_ID="$2"
      shift 2
      ;;
    --env)
      ENV="$2"
      shift 2
      ;;
    --tags-file)
      TAGS_FILE="$2"
      shift 2
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      print_usage
      exit 1
      ;;
  esac
done

# Validate mandatory parameters
[[ -n "$STACK_NAME" ]] || { echo "Error: --stack-name is required"; exit 1; }
[[ -n "$TEMPLATE_FILE" ]] || { echo "Error: --template-file is required"; exit 1; }
[[ -n "$PARAMS_FILE" ]] || { echo "Error: --params-file is required"; exit 1; }
[[ -n "$ENV" ]] || { echo "Error: --env is required"; exit 1; }
[[ -n "$ENV" ]] || { echo "Error: --account is required"; exit 1; }

# Validate files
[[ -f "$TEMPLATE_FILE" ]] || { echo "Template file not found: $TEMPLATE_FILE"; exit 1; }
[[ -f "$PARAMS_FILE" ]] || { echo "Parameters file not found: $PARAMS_FILE"; exit 1; }

DEF_TAGS=(Environment=$ENV Account=$AWS_ACCOUNT_ID)

TAGS_ARG=()
if [[ -n "$TAGS_FILE" ]]; then
  [[ -f "$TAGS_FILE" ]] || { echo "Tags file not found: $TAGS_FILE"; exit 1; }
  TAGS=$(grep -v '^$' "$TAGS_FILE" | xargs)
  TAGS_ARG=(--tags $TAGS $DEF_TAGS)
fi

if [[ -z "$TAGS_FILE" ]]; then
  TAGS_ARG=(--tags $DEF_TAGS)
fi

echo "Deploying stack: $STACK_NAME"
echo "Template file: $TEMPLATE_FILE"
echo "Parameters file: $PARAMS_FILE"
[[ -n "$TAGS_FILE" ]] && echo "Tags file: $TAGS_FILE"

aws cloudformation deploy \
  --stack-name "$STACK_NAME" \
  --template-file "$TEMPLATE_FILE" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides file://"$PARAMS_FILE" \
  "${TAGS_ARG[@]}"
