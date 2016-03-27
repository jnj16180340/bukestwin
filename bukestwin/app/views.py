from app import app
from flask import redirect, render_template, flash, jsonify

from .forms import InputForm
from app import q # RQ queue from __init_.py
from rq.job import Job
from worker import conn

import time # for testing
import simplejson as json

@app.route('/',methods=['GET','POST'])
def index():
    #return 'Smoke, Deew!'
    form = InputForm()
    
    if form.validate_on_submit():
        flash('Generating poem with title %s at drunkenness %s' %(form.titleSeed.data, str(form.howDrunk.data)))
        #return redirect('/')
        job = q.enqueue_call(func=generate_text, args=(form.titleSeed.data,form.howDrunk.data),result_ttl=300, timeout=60) # TODO: Adjust ttl (how long redis holds on to the result)
        # TODO: Other timeout options...?
        print(job.get_id()) # e.g. 66df343f-2841-4fd2-986d-b83d459a6693
        return render_template('reading.html', pageTitle=None, form=form, poemTitle=form.titleSeed.data, poemHowDrunk=str(form.howDrunk.data), poemContent='BIG ASS TITS', jobId = job.get_id())
    
    return render_template('reading.html', pageTitle=None, form=form, putput='')


@app.errorhandler(404)
def page_not_found(e):
    #return result
    return redirect('/', code=302, Response=None)


# should this be in views.py??
def generate_output(title, poem, howdrunk=None):
    ''' prettyprint a poem.'''
    # NB: \n doesn't render in html, this is quite problematic
    return 'TITLE: '+title+'<br><br>'+poem+'\n\n\n how drunk: '+howdrunk
    
@app.route("/results/", methods=['GET'])
def nothing_to_see_here():
    ''' crappy hack for when we get results with no job ID!
     this should be fixed in the javascript '''
    return "Nothing to see here!", 403
    
@app.route("/results/<job_key>", methods=['GET'])
def get_results(job_key):
    ''' check to see if job is finished '''
    job = Job.fetch(job_key, connection=conn)
    
    #if job.is_failed:
      #  return "Failed", 500 # 500 = internal server error

    if job.is_finished:
        #return str(job.result), 200 # OK
        keys = ('title', 'howdrunk', 'poem')
        print(job.result)
        return jsonify(zip(keys, job.result)),200
        #return "Yay", 200 # OK
    else:
        return "Nay", 202 # 202 = accepted (processing not completed)

##################################################################################3
### Call th sampling stuff
### This should be in a separate file
# should this be in views.py
def generate_text(seed, howdrunk):
    ''' calls th sample... 
    '''
    ''' This could be stored in a database, 
    instead of floating somewhere in redis-land.
    I'll keep it temporary for now, because it's
    not intended to have a very long lifespan...
    '''
    '''
    th sample.lua -checkpoint cv_0/cv3x512_39000.t7 -temperature 0.5 -gpu -1 -start_text "TITLE: shit fuck" -verbose 1 -length 50
    '''
    import os, subprocess

    # params: seed, howdrunk
    # returns: seed, howdrunk, text
    try:
        POEM_SEPARATOR = '\n\n'

        # TODO this is really shitty
        old_dir = os.getcwd()

        #os.chdir('../../torch-rnn/')
        os.chdir('/root/torch-rnn') # for running in docker
        #thecommand = 'th sample.lua -checkpoint cv_0/cv3x512_39000.t7 -length 2000 -gpu -1 -temperature 0.5 -start_text "TITLE: piss fuck"'
        #thecommand = 'th sample.lua -checkpoint cv_0/cv3x512_39000.t7 -length 2000 -gpu -1 -temperature '+str(howdrunk)+' -start_text "TITLE: '+seed+'"'
        # for docker, with checkpoints in /root/cv_0 etc
        # TODO this stuff is fragile
        thecommand = '/root/torch/install/bin/th sample.lua -checkpoint /root/cv_0/cv3x512_117000.t7 -length 2000 -gpu -1 -temperature '+str(howdrunk)+' -start_text "TITLE: '+seed+'"'
        theoutput = subprocess.getoutput(thecommand)
        print(theoutput)

        # TODO scan for complete chunk and seed NN with last line if necessary until done
        # also this fails when separator isn't quite perfect, splittting on title is better or do regex
        poem = theoutput.split(POEM_SEPARATOR)[0]
        # theoutput.split(POEM_SEPARATOR)[1].split('\n')[-1]

        # TODO this is reallyl shitty
        os.chdir(old_dir)
        seed = poem[:poem.find('\n')].replace('TITLE:','')
        return seed, howdrunk, poem[poem.find('\n'):].replace('\n','<br>')
    except:
        return 'shame',0.42,"there now is a server online\nthat's having a very bad time\nit ran lua-jit\nand crashed all to shit\nthen wrote you this very bad rhyme".replace('\n','<br>')