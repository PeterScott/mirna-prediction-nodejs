# Combine three files together in a joyous way, spreading harmony and
# bees. Output most serene HTML.

import re, sys
from cgi import escape

# Test for right number of arguments
if len(sys.argv) != 4:
    print 'usage: %s fasta file2 svout' % sys.argv[0]
    sys.exit(1)

# Open all the files, and read in their lines
fasta = open(sys.argv[1]).readlines()
file2 = open(sys.argv[2]).readlines()
svout = open(sys.argv[3]).readlines()

# Build a list of the names of the sequences in a FASTA file.
fasta_names = []
for line in fasta:
    line = line.strip()
    m = re.match(r'^>([^\s|]+)', line)
    if m: fasta_names.append(m.group(1))

# Build a list of the indices in fasta_names which were sent to SVM
result_nums = []
for line in file2:
    line = line.strip()
    m = re.match(r'^>([0-9]+)', line)
    if m: result_nums.append(int(m.group(1)) - 1)

# Create results vector. 0 means no hairpin, 1 means it's a pre-miRNA,
# -1 means it's a pseudo-pre-miRNA.
results = [0] * len(fasta_names)
i = 0
for line in svout:
    x = int(line.strip())
    results[result_nums[i]] = x
    i += 1

# Print the results in an HTML table. The table is nicely indented,
# and valid XHTML Strict. In case that matters.
descriptions = ['Pseudo pre-miRNA', 'No hairpin structure', 'True pre-miRNA']
print '<table id="triplet-svm-results" class="center">'
print '  <tr><th>Sequence name</th><th>Classification</th></tr>\n'
for name, result in zip(fasta_names, results):
    result_description = descriptions[result+1]
    print '  <tr class="result%d"><td>%s</td><td>%s</td></tr>' % (result+1, escape(name), result_description)
print '</table>'
