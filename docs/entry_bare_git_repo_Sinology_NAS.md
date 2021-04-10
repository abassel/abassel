# Initializing bare Git repo in Sinology NAS with one simple script

Created: 2018-04-02

Every time I start a new project; I need to initialize a new Git repo inside my NAS. So today I will automate that task with some scripting.

Basically, I want to trigger a script locally that creates the bare repo in the NAS at the same time it connects a local repo to the newly created remote

[comment]: <> (https://gist.github.com/MichaelCurrin/c2bece08f27c4277001f123898d16a7c)
[LABEL](https://gist.githubusercontent.com/abassel/0b747a4fa130cf7fb05b/raw/d5c158b018545dc790b0af98cd5a1a9d3464f68f/gitinit.sh ':include :type=code')

Let’s discuss few things about the script above:

1. The remote script is stored in a variable ( lines 18 to 22 ) so that we don’t need to create a second file, inject and then execute.
2. The NAS does not have Bash. It has ash and sh. For the basic syntax,  bash can run sh script and vice versa.
3. My Git server is storing its data in /All/Source-Code-my/Git_repo/ . That same folder is referenced in my cloud backup software so I have all my repos safe in the cloud!
4. My NAS is located at a fixed IP and the user name that is configured in the Git is Alex ( Alex@192.168.1.25 ) . You will need to update those values according to your situation.

[filename](footnote.md ':include')