# SupercoolNameinator
A reddit bot that "crowdsources" acronym definitions from reddit

https://www.reddit.com/r/SupercoolNameinator/wiki/index

###The Supercool Nameinator
is a bot that I (/u/superdisk) wrote as a way to learn Elixir/OTP. It's named after the Kids Next Door's "LUNCHBOCKS," which has a "Supercool Nameinator" program that generates phony acronyms-- for instance "BRA" -> "Battle Ready Armor."

###How it works:

1. The bot reads comments and finds people typing in Camel Case. For instance ["And Alec Baldwin"](http://reddit.com/comments/5gicrp/_/dat03ak) gets stored as "AAB"
2. The bot stores their "definition" for an acronym in a database.
3. Simultaneously, the bot reads comments for acronyms being used (series of capital letters)
4. If it finds one that's in the database, it comments the "definition" and reference comment from where it came.

That's it. My operation of the bot lasted 2 days, until it was banned by AskReddit and had all its comments deleted.

###Technical

The bot itself is written in Elixir, basically as a learning exercise- Huge thanks go out to Meh, Rob-Bie (for Amnesia and ElixirPlusReddit respectively) and the folks in the Elixir slack.

###How to make it run

1. Run `mix deps.get`
2. Create the mnesia database with `mix amnesia.create -db Database --disk`
3. Specify the subs you want it to run on, in `nameinator2.ex`
4. Create a `eprconfig.exs` file. Read `config.exs` for more info, it's super easy.
5. Finally run `iex -S mix` to start it.

------

![](https://b.thumbs.redditmedia.com/E0NYpRoJAd4sCNV7bGFKke9x-RrXjn5_93oj2lMoAbk.jpg)
