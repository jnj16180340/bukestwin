## b;ah
#!flask/bin/python3

from app import app
# this should not be in debug mode for deployment
app.run(debug=True, host='0.0.0.0', port=8000)