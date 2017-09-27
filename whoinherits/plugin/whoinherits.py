import vim
import re

def findSubclasses():
    list = vim.eval("a:list")
    clsToTest = vim.eval("a:cls")
    outputList = []
    for tup in list:
        if re.search('implements.*'+clsToTest,  tup['text']) or \
           re.search('extends.*'+clsToTest,     tup['text']):
            outputList.append(tup)

    if len(outputList):
        vim.command("call setqflist(" + str(outputList) + ")")
        vim.command("copen")
    else:
        vim.command("echo " + "'Subclasses of " + str(clsToTest) + " NOT FOUND'")

findSubclasses()
