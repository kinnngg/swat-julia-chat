class Extension extends Julia.Extension
 implements Julia.InterestedInEventBroadcast,
            Julia.InterestedInPlayerDisconnected;

/**
 * Copyright (c) 2014 Sergei Khoroshilov <kh.sergei@gmail.com>
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

struct sBotReply
{
    /**
     * Reference to the player this reply has been addressed to
     * @type class'Julia.Player'
     */
    var Julia.Player Player;

    /**
     * Time the reply was queued at (Level.TimeSeconds)
     * @type float
     */
    var float TimeQueued;

    /**
     * Reply message
     * @type string
     */
    var string Message;

    /**
     * Indicate whether the message has already been sent or still awaiting
     * @type bool
     */
    var bool bReplied;
};

/**
 * List of dispatched replies
 * @type array<sBotReply>
 */
var protected array<sBotReply> BotReplies;

/**
 * List of chatbot templates (e.g. "hi (all|guys)")
 * @type array<string>
 */
var config array<string> Templates;

/**
 * List of template-corresponding chatbot replies
 * @type array<string>
 */
var config array<string> Replies;

/**
 * Time a player has wait before they can interact with bot again
 * @type float
 */
var config float ReplyThreshold;

/**
 * Time in seconds bot will wait before replying to a matched templated
 * @type float
 */
var config float ReplyDelay;

/**
 * Register with the julia's core signal handler
 * 
 * @return  void
 */
public function BeginPlay()
{
    Super.BeginPlay();

    self.Core.RegisterInterestedInEventBroadcast(self);
    self.Core.RegisterInterestedInPlayerDisconnected(self);
}

event Timer()
{
    self.HandleBotReplies();
}

/**
 * Attempt to match a Say message against the list of chatbot templates
 * 
 * @see Julia.InterestedInEventBroadcast.OnEventBroadcast
 */
public function bool OnEventBroadcast(Julia.Player Player, Actor Sender, name Type, string Msg, optional PlayerController Receiver, optional bool bHidden)
{
    local string Reply;

    if (!bHidden)
    {
        if (Type == 'Say')
        {
            if (Player != None && self.IsAllowedToInteract(Player))
            {
                if (self.ValidateTemplate(Msg, Reply))
                {
                    self.QueueReply(Reply, Player);
                }
            }
        }
    }
    return true;
}

/**
 * Attempt to parse a message against the list of chatbot templates
 * 
 * @param   string Message
 *          Original message
 * @param   string Reply (out)
 *          Random reply corresponding to the matched template
 * @return  bool
 */
protected function bool ValidateTemplate(string Message, out string Reply)
{
    local int i, j;
    local array<string> ParsedTemplates, ParsedReplies;

    for (i = 0; i < self.Templates.Length; i++)
    {
        if (self.Replies[i] == "")
        {
            continue;
        }
        else if (i >= self.Replies.Length)
        {
            break;
        }

        ParsedTemplates = class'Utils.StringUtils'.static.Part(self.Templates[i], "#");
        ParsedReplies = class'Utils.StringUtils'.static.Part(self.Replies[i], "#");

        if (ParsedTemplates.Length == 0 || ParsedReplies.Length == 0)
        {
            continue;
        }

        for (j = 0; j < ParsedTemplates.Length; j++)
        {
            if (class'Utils.StringUtils'.static.Match(Message, ParsedTemplates[j]))
            {
                Reply = class'Utils.ArrayUtils'.static.Random(ParsedReplies);
                return true;
            }
        }
    }
    return false;
}

/**
 * Remove the player's reference from the list of dispatched replies
 * 
 * @param   class'Julia.Player' Player
 * @return  void
 */
public function OnPlayerDisconnected(Julia.Player Player)
{
    local int i;

    for (i = self.BotReplies.Length-1; i >= 0 ; i--)
    {
        if (self.BotReplies[i].Player == Player)
        {
            self.BotReplies[i].Player = None;
            self.BotReplies.Remove(i, 1);
        }
    }
}

/**
 * Attempt to reply to a player with a dispatched reply
 * 
 * @return  void
 */
protected function HandleBotReplies()
{
    local int i;

    for (i = self.BotReplies.Length-1; i >= 0; i--)
    {
        // Reply to a player
        if (!self.BotReplies[i].bReplied)
        {
            if (self.BotReplies[i].TimeQueued + self.ReplyDelay <= Level.TimeSeconds)
            {
                self.Reply(self.BotReplies[i].Message, self.BotReplies[i].Player);
                self.BotReplies[i].Message = "";
                self.BotReplies[i].bReplied = true;
            }
        }
        else if (self.BotReplies[i].TimeQueued + self.ReplyThreshold < Level.TimeSeconds)
        {
            self.BotReplies.Remove(i, 1);
        }
    }
}

/**
 * Reply to a player
 * 
 * @param   string Message
 * @param   class'Julia.Player' Player
 * @return  void
 */
protected function Reply(string Message, Julia.Player Player)
{
    local int i;
    local array<string> Lines;

    // Split lines
    Lines = class'Utils.StringUtils'.static.Part(class'Utils.StringUtils'.static.NormNewline(Message), "\n");

    if (Lines.Length == 0)
    {
        return;
    }
    // Display the first line
    class'Utils.LevelUtils'.static.TellAll(
        Level,
        self.Locale.Translate("ReplyMessage", self.FormatReplyMessage(Lines[0], Player)),
        self.Locale.Translate("ReplyColor")
    );
    Lines.Remove(0, 1);
    // Display the other lines
    for (i = 0; i < Lines.Length; i++)
    {
        class'Utils.LevelUtils'.static.TellAll(
            Level, self.FormatReplyMessage(Lines[i], Player), self.Locale.Translate("ReplyColor")
        );
    }
}

/**
 * Queue a new chatbot reply
 * 
 * @param   string Message
 * @param   class'Julia.Player' Player
 * @return  void
 */
protected function QueueReply(string Message, Julia.Player Player)
{
    local sBotReply NewReply;

    NewReply.Player = Player;
    NewReply.Message = Message;
    NewReply.TimeQueued = Level.TimeSeconds;

    self.BotReplies[self.BotReplies.Length] = NewReply;
}

/**
 * Interpolate a reply message with variable values
 * 
 * @param   string Message
 * @param   class'Julia.Player' Player
 * @return  string
 */
protected function string FormatReplyMessage(coerce string Message, Julia.Player Player)
{
    local array<string> Vars;
    local string Value;
    local int i;

    Vars[0] = "name";
    Vars[1] = "time";
    Vars[2] = "nextmap";
    Vars[3] = "random";

    for (i = 0; i < Vars.Length; i++)
    {
        if (InStr(Message, "%" $ Vars[i] $ "%") >= 0)
        {
            switch (Vars[i])
            {
                case "name" :
                    Value = Player.GetName();
                    break;
                case "time" :
                    Value = class'Utils.LevelUtils'.static.FormatTime(class'Utils.LevelUtils'.static.GetTime(Level), "%H:%M");
                    break;
                case "nextmap" :
                    Value = class'Julia.Utils'.static.GetFriendlyMapName(class'Julia.Utils'.static.GetNextMap(Level));
                    break;
                case "random" :
                    Value = self.GetRandomName(Player);
                    break;
                default :
                    Value = "";
            }
            Message = class'Utils.StringUtils'.static.Replace(Message, "%" $ Vars[i] $ "%", Value);
        }
    }
    return Message;
}

/**
 * Tell whether a player is allowed to interact with chatbot at the moment
 * 
 * @param   class'Julia.Player'
 * @return  bool
 */
protected function bool IsAllowedToInteract(Julia.Player Player)
{
    local int i;

    for (i = 0; i < self.BotReplies.Length; i++)
    {
        if (self.BotReplies[i].Player == Player)
        {
            return false;
        }
    }

    return true;
}

/**
 * Return name of a random online player. 
 * Use the FallbackPlayer's name as the last resort
 * 
 * @param   class'Julia.Player' FallbackPlayer
 * @return  string
 */
protected function string GetRandomName(Julia.Player FallbackPlayer)
{
    local array<Player> Players;
    local array<string> Names;
    local int i;

    Players = self.Core.GetPlayers();

    for (i = 0; i < Players.Length; i++)
    {
        if (Players[i].GetPC() != None && Players[i] != FallbackPlayer)
        {
            Names[Names.Length] = Players[i].GetName();
        }
    }
    if (Names.Length > 0)
    {
        return class'Utils.ArrayUtils'.static.Random(Names);
    }
    return FallbackPlayer.GetName();
}

event Destroyed()
{
    if (self.Core != None)
    {
        self.Core.UnregisterInterestedInEventBroadcast(self);
        self.Core.UnregisterInterestedInPlayerDisconnected(self);
    }
    
    while (self.BotReplies.Length > 0)
    {
        self.BotReplies[0].Player = None;
        self.BotReplies.Remove(0, 1);
    }

    Super.Destroyed();
}

defaultproperties
{
    Title="Julia/Chat";
    Version="1.0.0";
    LocaleClass=class'Locale';

    ReplyThreshold=2.0;
    ReplyDelay=0.5;
}

/* vim: set ft=java: */