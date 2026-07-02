#!/bin/bash
MODEL="${1:-opencode/mimo-v2.5-free}"
opencode run --model "$MODEL" "/multi-agents-dev init"
