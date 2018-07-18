#!/usr/bin/env ruby
require 'open-uri'
require 'json'

def issue_data(key)
  username = ENV['JIRA_USERNAME']
  password = ENV['JIRA_PASSWORD']
  url = "https://jira.2u.com/rest/api/2/issue/#{key}?fields=assignee,summary,issuetype"
  open(url, http_basic_authentication: [username, password]) {|f| return JSON.parse(f.read) }
end

def create_new_branch(name)
  system("git checkout -b #{name}")
end

subcommands = ['new-branch']

subcommand = ARGV[0]
if !subcommands.include?(subcommand)
  p "Accepted subcommands #{subcommands}"
  exit
end

if subcommand == 'new-branch'
  issue_key = ARGV[1]
  issue = issue_data(issue_key)
  fields = issue['fields']
  issue_type_name = fields['issuetype']['name']
  issue_summary = fields['summary']

  print "Creating new branch for [#{issue_key}] #{issue_summary}"
  branch_name = "#{issue_key.downcase}-#{issue_type_name.downcase}"
  create_new_branch(branch_name)
end
