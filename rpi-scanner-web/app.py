from flask import Flask, render_template, request, redirect, url_for, session
import subprocess

app = Flask(__name__)
app.secret_key = 'your-super-secret-key'  # Use a secure, random value

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        password = request.form.get('password')
        if password == 'password':  # Replace with your desired password
            session['logged_in'] = True
            return redirect(url_for('home'))
        else:
            return render_template('login.html', error="Invalid password")
    return render_template('login.html')

@app.route('/')
def home():
    if not session.get('logged_in'):
        return redirect(url_for('login'))
    
    # Show the network scanner dashboard or devices
    scan_output = run_scan()
    return render_template('index.html', output=scan_output)

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))

def run_scan():
    result = subprocess.run(["sudo", "./network-map.sh"], capture_output=True, text=True)
    return result.stdout

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
