# Combine MiPred results files for great good. Output HMTL.

import re, sys
from cgi import escape

# Test for right number of arguments
if len(sys.argv) != 2:
    print 'usage: %s mipred_output' % sys.argv[0]
    sys.exit(1)

# Open the MiPred output file, and read its lines
miout = open(sys.argv[1]).readlines()

# Output HTML. This is nasty code, but it works.
descriptions = ['Pseudo pre-miRNA', 'No hairpin structure', 'True pre-miRNA']
print '<table id="mipred-results" class="center">'
print '  <tr><th>Sequence name</th><th>Classification</th><th>Confidence*</th></tr>\n'
seqname, result = 'missingno', 1 # dummy values
for line in miout:
    line = line.strip()
    m = re.match(r'^Sequence Name:\s*([^\s|]+)', line)
    if m:
        seqname = m.group(1)
    else:
        m = re.match(r'Prediction result:[^rpn]*([rpn])', line)
        if m:
            result = {'r': 2, 'p': 0, 'n': 1}[m.group(1)]
            if result == 1:
                result_description = descriptions[result]
                print '  <tr class="result%d"><td>%s</td><td>%s</td><td></td></tr>' % (result, escape(seqname), result_description)
        else:
            m = re.match(r'Prediction confidence:\s*([0-9.]+%)', line)
            if m:
                result_description = descriptions[result]
                print '  <tr class="result%d"><td>%s</td><td>%s</td><td>%s</td></tr>' % (result, escape(seqname), result_description, m.group(1))
print '</table>'
print '<p>*Confidence values probably do not mean what you think they mean.</p>'
