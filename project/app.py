#!/usr/bin/env python
import ConfigParser
import json
import socket

# Required for Flask Basic Authentication
from functools import wraps

# Read Config
Config = ConfigParser.ConfigParser()
Config.read("config.ini")

__appname__ = Config.get('bbio', 'app_name')
__author__  = Config.get('bbio', 'author')
__version__ = Config.get('bbio', 'bbio_api_version')
__license__ = Config.get('bbio', 'license')

# Start Flask
from flask import Flask, jsonify, render_template, request, Response, json, redirect, url_for, send_from_directory
app = Flask(__name__)
app.logger.info("Starting Flask")

# Set hostname
hostname = socket.gethostname()
app.logger.info('Hostname {}'.format(hostname))

# Define error handling
def error(message):
  app.logger.error(message)

# Place holder for anything we want to do at launch
def startup():
  app.logger.info('Starting Brown Bag IO')

# Check config, specifically to see if authorization is required
def check_config():
  app.logger.info('Parsing config options')
  try:
    auth_required = Config.get('options', 'auth_required')
  except:
    auth_required = False

try:
  auth_required
  app.logger.info('Authentication required')
  # Import plugins
  import plugins.bbio_auth
  bbio_auth = plugins.bbio_auth.bbioAuth()
  app.logger.info('Module loaded {}'.format(bbio_auth))

  # Message for failed attempts
  def authentication_fail():
    """Sends a 401 response that enables basic auth"""
    return Response(
    'Could not verify your access level for that URL.\n'
    'You must login with proper credentials', 401,
    {'WWW-Authenticate': 'Basic realm="Login Required"'})

  def requires_auth(f):
    @wraps(f)
    def api_login(*args, **kwargs):
      auth = request.authorization
      app.logger.info("api_login username: ({})".format(auth.username))
      auth_check = bbio_auth.auth_check(user=auth.username, passw=auth.password)
      app.logger.info("ldap_check:  ".format(ldap_check))
      if not auth or not auth_check:
        app.logger.info("Authentication failure for user {}".format(auth.username))
        return authentication_fail()
      else:
        return_data = f(*args, **kwargs)
        app.logger.info("Authentication successful for user {}".format(auth.username))
        return return_data
    return api_login
except:
  app.logger.info('Authentication not required')
  def requires_auth(f):
    @wraps(f)
    def no_auth(*args, **kwargs):
      return f(*args, **kwargs)
    return no_auth

# Do the stuff above
startup()
check_config()

## API Routes

# Verbose health check to ensure basic functionality
@app.route('/api/v1.0/bbio/health')
@requires_auth
def bbio_api_health_check():
  try:
    app.logger.info("bbio_api_health_check()")
    results = {
      'message': '{} is running!'.format(__appname__),
      'status': 'running',
      }
    return_data = json.dumps({'result': results})
    app.logger.info(return_data)
    return return_data, 200
  except Exception as e:
    error(e)

# Webpages

@app.route('/')
@requires_auth
def index():
  app.logger.info("index()")
  return render_template('index.html', title=__appname__)

@app.route('/health')
@requires_auth
def health():
  app.logger.info("health()")
  return render_template('health.html', title=__appname__)

if __name__ == '__main__':
  app.run(
      host="0.0.0.0",
      port=5000,
      debug=True
  )



