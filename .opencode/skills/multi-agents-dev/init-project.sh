#!/bin/bash
MODEL="${1:-opencode/mimo-v2.5-free}"
opencode run --model "$MODEL" "/multi-agents-dev init"
agent --yolo "npx skills add https://github.com/obra/superpowers --skill brainstorming"
agent --yolo "npx skills add https://github.com/obra/superpowers --skill writing-plans"
agent --yolo "npx skills add https://github.com/obra/superpowers --skill receiving-code-review"