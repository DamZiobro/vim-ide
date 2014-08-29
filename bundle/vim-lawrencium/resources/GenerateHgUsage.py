import re
import urllib2
from BeautifulSoup import BeautifulSoup

# Load the documentation page.
print "Loading HG documentation from selenic.com..."
url = urllib2.urlopen("http://www.selenic.com/mercurial/hg.1.html")
soup = BeautifulSoup(url)

# Open the output file.
output = 'hg_usage.vim'
f = open(output, 'w')

# A little header for people peeking in there.
f.write("\" LAWRENCIUM - MERCURIAL USAGE\n")
f.write("\" This file is generated automatically.\n")
f.write("\n")

# Start with the global options.
f.write("let g:lawrencium_hg_options = [\n")
for option in soup.find('div', id='options').findAll('span', {'class': 'option'}):
    f.write("    \\'%s',\n" % option.string)
f.write("    \\]\n")
f.write("\n")

# Now get the usage for all commands.
f.write("let g:lawrencium_hg_commands = {\n")
for command in soup.find('div', id='commands').findAll('div', {'class': 'section'}):
    print " - %s" % format(command.h2.string) 
    f.write("    \\'%s': [\n" % command.h2.string)
    option_table = command.find('table', { 'class': re.compile('option-list') })
    if option_table:
        for option in option_table.findAll('span', { 'class': 'option'}):
            f.write("        \\'%s',\n" % option.string)
    f.write("        \\],\n")
f.write("    \\}\n")
f.write("\n")

# Close the output file, and we're done.
f.close()
print "Done!"

