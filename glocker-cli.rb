#!/usr/bin/env ruby
require 'open-uri'
require 'json'

DIR = "#{Dir.home}/.glocker/"

def issue_data(key)
  username = ENV['JIRA_USERNAME']
  password = ENV['JIRA_PASSWORD']
  url = "https://jira.2u.com/rest/api/2/issue/#{key}?fields=assignee,summary,issuetype"
  open(url, http_basic_authentication: [username, password]) {|f| return JSON.parse(f.read) }
end

def create_new_branch(name)
  system("git checkout -b #{name}")
end

def create_pull_request
  root_project_dir = `git rev-parse --show-toplevel`
  pr_template_path = "#{root_project_dir.strip}/.github/pull_request_template.md"
  branch = `git rev-parse --abbrev-ref HEAD`
  res = read_glocker_file(branch.strip)
  # https://developer.github.com/v3/pulls/#create-a-pull-request
  # Fill out the template using information
  key = res['key']
  summary = res['summary']
  type = res['type']
  title = "[#{key}][#{type}] #{summary}"
  body = format_template_file(pr_template_path, substitution: [
    "https://jira.2u.com/browse/<your-ticket-id>",
    "https://jira.2u.com/browse/#{key}"
  ])

  print "Creating PR with title: \n"
  print "#{title}\n"
  print "-------------\n"
  print "#{body}\n"
end

def format_template_file(path, substitution:)
  f = File.new(path, 'r')
  contents = f.read
  contents.gsub(substitution[0], substitution[1])
end

def open_issue
  branch = `git rev-parse --abbrev-ref HEAD`
  res = read_glocker_file(branch.strip)
  url = "https://jira.2u.com/browse/#{res['key']}"
  `open #{url}`
end

def read_glocker_file(name)
  f = File.new("#{DIR}#{name}", 'r')
  JSON.parse(f.read)
end

def create_glocker_file(name, data)
  if !Dir.exists?(DIR)
    Dir.mkdir(DIR)
  end
  f = File.new("#{DIR}#{name}", 'w')
  f.write(data.to_json)
end

subcommands = [
  'new-branch',
  'open',
  'create-pr'
]

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
  print "Creating new branch for [#{issue_key}] #{issue_summary} ...\n"
  branch_name = "#{issue_key.downcase}-#{issue_type_name.downcase}"
  create_new_branch(branch_name)
  print "Creating glocker file #{branch_name} ... \n"
  create_glocker_file(branch_name, {
    key: issue_key,
    summary: issue_summary,
    type: issue_type_name,
    date_created: Time.now.utc
  })
elsif subcommand == 'open'
  open_issue
elsif subcommand == 'create-pr'
  create_pull_request
end
