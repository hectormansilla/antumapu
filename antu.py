from flask import Flask, render_template, request, redirect, url_for, make_response
from flask_sqlalchemy import SQLAlchemy
import pdfkit
import datetime

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://user:pass@127.0.0.1/mapu'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

class Running(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    malla = db.Column(db.String(16))
    proceso = db.Column(db.String(8))
    estado = db.Column(db.String(1))
    ws = db.Column(db.String(4))
    opnum = db.Column(db.Integer)
    inicio = db.Column(db.DateTime(timezone=False), nullable=False)

class Pending(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    malla = db.Column(db.String(16))
    proceso = db.Column(db.String(8))
    ws = db.Column(db.String(4))
    opnum = db.Column(db.Integer)
    inicio = db.Column(db.DateTime(timezone=False), nullable=False)
    ahora = db.Column(db.Time(timezone=False), nullable=False)

class Worklog(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    comentario = db.Column(db.Text)
    operador = db.Column(db.String(50))
    ahora = db.Column(db.DateTime(timezone=False), nullable=False)
    timeout_id = db.Column(db.Integer, db.ForeignKey('timeout.id'),
    nullable=False)


class Timeout(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    malla = db.Column(db.String(16))
    proceso = db.Column(db.String(8))
    ws = db.Column(db.String(4))
    opnum = db.Column(db.Integer)
    inicio = db.Column(db.DateTime(timezone=False), nullable=False)
    promedio = db.Column(db.Time(timezone=False), nullable=False)
    ejecucion = db.Column(db.DateTime(timezone=False), nullable=False)
    ahora = db.Column(db.DateTime(timezone=False), nullable=False)
    justificar = db.Column(db.Boolean)
    worklogs = db.relationship('Worklog',
        backref=db.backref('timeouts', lazy=True))

class Limiter(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    malla = db.Column(db.String(16))
    proceso = db.Column(db.String(8))
    ws = db.Column(db.String(4))
    opnum = db.Column(db.Integer)
    promedio = db.Column(db.Time(timezone=False), nullable=False)

@app.route('/')
def home():
    tasks = Timeout.query.all()
    return render_template('index.html.j2', tasks = tasks)

@app.route('/excuse/<id>')
def excuse(id):
    task = Timeout.query.filter_by(id=int(id)).first()
    return render_template('excuse.html.j2', task = task)

@app.route('/worklog-add', methods=['POST'])
def worklogadd():
    worklog = Worklog(operador = request.form['operador'],
                      timeout_id = request.form['timeout_id'],
                      comentario = request.form['comentario'],
                      ahora = datetime.datetime.now())
    db.session.add(worklog)
    task = Timeout.query.filter_by(id=request.form['timeout_id']).first()
    task.justificar = False
    db.session.commit()
    return redirect(url_for('home'))

@app.route('/report/<id>')
def report(id):
    task = Timeout.query.all()
    rendered = render_template('excuse.html.j2', task = task)
    pdf = pdfkit.from_string(rendered, False)
    response = make_response(pdf)
    response.headers['Content-Type'] = 'application/pdf'
    response.headers['Content-Disposition'] = 'inline; filename=output.pdf'
    return response

@app.route('/tiemposexcedidos')
def tiemposexcedidos():
    tasks = Timeout.query.all()
    return render_template('tiemposexcedidos.html.j2', tasks = tasks)

@app.route('/grte', methods=['POST'])
def grte():
    fecha = request.form['fecha']
    tasks = Worklog.query.order_by(Worklog.timeout_id).order_by(Worklog.ahora).all()
    rendered = render_template('report2.html.j2', tasks = tasks, fecha = fecha)
    pdf = pdfkit.from_string(rendered, False)
    response = make_response(pdf)
    response.headers['Content-Type'] = 'application/pdf'
    response.headers['Content-Disposition'] = 'inline; filename=TiemposExcedidos.pdf'

    return response

@app.route('/noinformados/')
def noinformados():
    tasks = Pending.query.all()
    rendered = render_template('report3.html.j2', tasks = tasks)
    pdf = pdfkit.from_string(rendered, False)
    response = make_response(pdf)
    response.headers['Content-Type'] = 'application/pdf'
    response.headers['Content-Disposition'] = 'inline; filename=ProcesosSinInformacion.pdf'
    Pending.query.delete()
    db.session.query(Pending).delete()
    db.session.commit()
    return response

if __name__ == '__main__':
    app.run(debug=True)
