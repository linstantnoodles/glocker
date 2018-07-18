#!/usr/bin/env ruby

require 'open-uri'
require 'json'

def print_with_formatting(lines)
  lines.each do |l|
    print "#{l}\n"
  end
end

# https://jira.2u.com/rest/agile/1.0/sprint/1357/issue?fields=summary
# https://jira.2u.com/rest/greenhopper/1.0/sprintquery/446
#/rest/agile/1.0/board/446/backlog
# another option: use search: https://community.atlassian.com/t5/Jira-questions/How-do-I-retrieve-issues-of-specific-status-with-JQL/qaq-p/540468
def show_issues
  open(url, http_basic_authentication: [username, password]) {|f|
    response = f.read
    res = JSON.parse(response)
    issues = res['issues']
    lines_to_print = issues.map do |issue|
      key = issue['key']
      summary = issue['fields']['summary']
      assignee_name = issue.dig('fields', 'assignee', 'name')
      clickable_link = "https://jira.2u.com/browse/#{key}"
      "#{key} - #{summary} [#{assignee_name}] (#{clickable_link})"
    end
    print_with_formatting(lines_to_print)
  }
end

subcommands = ['new-branch']

subcommand = ARGV[0]
if !subcommands.include?(subcommand)
  p "Accepted subcommands #{subcommands}"
  exit
end

if subcommand == 'new-branch'
  username = ENV['JIRA_USERNAME']
  password = ENV['JIRA_PASSWORD']
  issue_key = ARGV[1]
  issue_endpoint = "https://jira.2u.com/rest/api/2/issue/#{issue_key}"
  p ticket_url
end