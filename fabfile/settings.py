# -*- coding: utf-8 -*-
import os

from unipath import Path
from fabric.api import *


env.kits = {
    'swat4': {
        'mod': 'Mod',
        'content': 'Content',
        'server': 'Swat4DedicatedServer.exe',
        'ini': 'Swat4DedicatedServer.ini',
    },
    'swat4exp': {
        'mod': 'ModX',
        'content': 'ContentExpansion',
        'server': 'Swat4XDedicatedServer.exe',
        'ini': 'Swat4XDedicatedServer.ini',
    },
}

env.roledefs = {
    'ucc': ['vm-ubuntu-swat'],
    'server': ['vm-ubuntu-swat'],
}

env.paths = {
    'here': Path(os.path.dirname(__file__)).parent,
}

env.paths.update({
    'dist': env.paths['here'].child('dist'),
    'compiled': env.paths['here'].child('compiled'),
})

env.ucc = {
    'path': Path('/home/sergei/swat4ucc/'),
    'git': 'git@home:public/swat4#origin/ucc',
    'packages': (
        ('Utils', 'git@home:swat/swat-utils'),
        ('Julia', 'git@home:swat/swat-julia'),
        ('JuliaChat', 'git@home:swat/swat-julia-chat'),
    ),
}

env.server = {
    'path': Path('/home/sergei/swat4server/'),
    'git': 'git@home:public/swat4#origin/server',
    'settings': {
        '+[Engine.GameEngine]': (
            'ServerActors=Utils.Package',
            'ServerActors=Julia.Core',
            'ServerActors=JuliaChat.Extension',
        ),
        '[Julia.Core]': (
            'Enabled=True',
        ),
        '[JuliaChat.Locale]': (
            r'ReplyMessage=[b]Jess (AdminBot)[\b]: %1',
        ),
        '[JuliaChat.Extension]': (
            'Enabled=True',
            'ReplyDelay=0.5',
            'ReplyThreshold=0.0',
            
            r"Templates=*(hi|ello|hey|yo) *again*#*i*m back*",
            r"Replies=Welcome back!#Hi, where have you been?#Hi. I missed you.. NOT!#Hi, again...#Hey [b]%name%[\b].#Welcome back, [b]%name%[\b].#Hi [b]%name[\b]! It's nice to see you again.",
            
            r"Templates=*(hi|ello|hey|yo|morning|evening|noon|hiya) *(all|guys|every)*",
            r"Replies=Hello, fellow gamer. Enjoy your stay.#Hello [b]%name%[\b].#Hey [b]%name%[\b].#Hi!#Hello there, [b]%name%[\b].#Hey, what's up?#Greetings, [b]%name%[\b].#Welcome to the server, [b]%name%[\b].#Hi [b]%name%[\b]!#Hey [b]%name%[\b]. Have fun!#Hi [b]%name%[\b]. Follow the rules and have fun!#Hiya [b]%name%[\b].",
            
            r"Templates=*(bb|bye|goodbye|cya|see y*|night|nite|gn) *(all|guys)*#*(have*go|gtg|g2g|got*go)( *|)",
            r"Replies=Goodbye [b]%name%[\b]. Take care.#See you later, [b]%name%[\b].#Bye.#See you later.#See you, [b]%name%[\b]. Be good.#Bye.#See ya, [b]%name%[\b]. Keep your nose clean.#Goodbye [b]%name%[\b], come back soon!#So long, [b]%name%[\b]. See you later.",
        ),
    }
}

env.dist = {
    'version': '1.0.0',
    'extra': (
        env.paths['here'].child('LICENSE'),
        env.paths['here'].child('README.html'),
        env.paths['here'].child('CHANGES.html'),
    )
}