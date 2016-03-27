import os, subprocess

# params: seed, howdrunk
# returns: seed, howdrunk, text

POEM_SEPARATOR = '\n\n'

# TODO this is really shitty
old_dir = os.getcwd()

os.chdir('../../torch-rnn/')
#thecommand = 'th sample.lua -checkpoint cv_0/cv3x512_39000.t7 -length 2000 -gpu -1 -temperature 0.5 -start_text "TITLE: piss fuck"'
thecommand = 'th sample.lua -checkpoint cv_0/cv3x512_39000.t7 -length 2000 -gpu -1 -temperature'+str(howdrunk)+' -start_text "TITLE: '+seed+'"'
theoutput = subprocess.getoutput(thecommand)
print(theoutput)

# TODO scan for complete chunk and seed NN with last line if necessary until done
if POEM_SEPARATOR in theoutput:
    text = theoutput.split(POEM_SEPARATOR)
else:
    # theoutput.split(POEM_SEPARATOR)[1].split('\n')[-1]
    text = theoutput

# TODO this is reallyl shitty
os.chdir(old_dir)
