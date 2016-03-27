from flask.ext.wtf import Form
from wtforms import StringField, FloatField
from wtforms.fields.html5 import DecimalRangeField
from wtforms.validators import DataRequired, NumberRange, Length

class InputForm(Form):
    titleSeed = StringField('title:', validators=[DataRequired(message='needs data'), Length(min=1, max=140, message='0...140chars')],render_kw={"placeholder": "an inspiring title"})
    #howDrunk = FloatField('howDrunk', validators=[NumberRange(min=0.1, max=1,message='drunk ∈ (0,1]')], default=0.5) # works down to 0.05 (not at 0.01)
    howDrunk = DecimalRangeField('how drunk?', validators=[NumberRange(min=0.09, max=1,message='∈ (0,1]')], default=0.65, render_kw={"min": "0.1","max":"1","step":"0.01"}) # works down to 0.05 (not at 0.01)