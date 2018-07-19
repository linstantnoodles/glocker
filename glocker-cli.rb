#!/usr/bin/env ruby
require 'open-uri'
require 'net/https'
require 'json'
require 'yaml'

DIR = "#{Dir.home}/.glocker/"
SECRETS_FILE = "#{DIR}secrets.yaml"

def issue_data(key)
  username = load_secrets['jira_username']
  password = load_secrets['jira_password']
  url = "https://jira.2u.com/rest/api/2/issue/#{key}?fields=assignee,summary,issuetype"

  open(url, http_basic_authentication: [username, password]) {|f| return JSON.parse(f.read) }
end

def load_secrets
  YAML.load_file(SECRETS_FILE)
end

def create_new_branch(name)
  system("git checkout -b #{name}")
end

def create_pull_request
  print "Pushing branch to remote ...\n"

  `git push`

  github_token = load_secrets['github_token']
  root_project_dir = `git rev-parse --show-toplevel`
  pr_template_path = "#{root_project_dir.strip}/.github/pull_request_template.md"
  branch = `git rev-parse --abbrev-ref HEAD`.strip
  res = read_glocker_file(branch)
  key = res['key'].upcase
  summary = res['summary']
  type = res['type']
  title = "[#{key}][#{type}] #{summary}"
  body = format_template_file(pr_template_path, substitution: [
    "https://jira.2u.com/browse/<your-ticket-id>",
    "https://jira.2u.com/browse/#{key}"
  ])
  remote_origin = `git config --get remote.origin.url`
  matches = remote_origin.match(/(git@github\.com):(\w+)\/(\w+)\.git/)
  owner = matches[2]
  repo = matches[3]
  print "Creating PR with title for project #{repo} for owner #{owner}: \n"
  print "\n"
  print "#{title}\n"
  print "-------------\n"
  print "#{body}\n"

  STDOUT.puts "Confirm? y/n"
  input = STDIN.gets.chomp
  raise "Aborting PR Creation." unless input.downcase == 'y'
  print "Creating PR ...\n"
  print "\n"
  data = {
    title: title,
    body: body,
    head: branch,
    base: 'master'
  }
  api_endpoint = "https://api.github.com/repos/#{owner}/#{repo}/pulls?access_token=#{github_token}"
  uri = URI.parse(api_endpoint)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Post.new(uri.request_uri)
  request['Content-Type'] = 'applicaton/json'
  request.body = data.to_json
  response = http.request(request)
  if response.code != '201'
    p response.body
  end
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
