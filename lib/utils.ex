defmodule Nameinator2.Utils do
    alias ElixirPlusReddit.API.Post
    require Amnesia.Helper
    require Logger
    use Database

    #Commons, when found, are put through a random chance to get posted. They're common
    #so obviously you don't want to see them all the time

    @commons MapSet.new(["MAGA", "PTSD", "GOAT", "YMMV", "GTFO", "CSGO", "AFAIK", "GTAV", 
    "TLOU", "IDK", "OMG", "LOL", "WTF", "RIP", "AMA", "TIL", "WOW", "NYC", "MMO", "DVD",
    "GTA", "SNL", "THE"])

    #Never define these. THey're so common and have the same result every time.
    @never MapSet.new(["ITS", "ALL", "HOW", "TIL", "ANY", "FTFY", "ITT", "BTW", "OCD",
    "DIE", "DID"])

    def unixTimestamp do
        {mega, secs, _} = :erlang.now
        mega*1000000 + secs
    end

    def containsNonAlpha?(word) do
        not (word
        |> to_charlist
        |> Enum.map(fn(x) -> (x >= 65 and x <= 90) end)
        |> Enum.all?)
    end

    def removeNonAlpha(word) do
        word
        |> to_charlist
        |> Enum.filter(fn(x) -> (x >= 65 and x <= 90) end)
        |> to_string
    end

    def takeUntilNonAlpha(word) do
        word
        |> to_charlist
        |> Enum.take_while(fn(x) -> (x >= 65 and x <= 90) end)
        |> to_string
    end

    def isCapitalLetter?(letter) do
        String.capitalize(letter) == letter
    end

    def isCaps?(word) do
        String.at(word, 0) |> isCapitalLetter?
    end

    def isAllCaps?(word) do
        word
        |> String.graphemes
        |> Enum.all?(&isCapitalLetter?/1)
    end

    def isEmptyString?(word) do
        word == ""
    end

    def isTHICC?(word) do
        word
        |> String.split(" ")
        |> Enum.all?(fn(x)->(String.length(x) == 1) end)
    end

    def endsWithPunctuation?(word) do
        String.ends_with?(word, ".") or
        String.ends_with?(word, "!") or
        String.ends_with?(word, "?")
    end

    def findAcronymDefinition(sentence) do
        acronym = sentence
        |> String.split
        |> Enum.chunk_by(fn(x) -> isCaps?(x) end)
        |> Enum.filter(fn(x) -> Enum.all?(x, &isCaps?/1) end)
        |> Enum.reject(fn(x) -> Enum.count(x) < 3 end)
        |> List.first

        case acronym do
            nil ->
                {"", ""}
            _ ->
                acronym = 
                Enum.take_while(acronym, fn(x)-> not endsWithPunctuation?(x) end)
                ++ Enum.slice(Enum.drop_while(acronym, fn(x)-> not endsWithPunctuation?(x) end), 0, 1)

                initialism = acronym
                |> Enum.map(&String.first/1)
                |> Enum.join("")

                {initialism, Enum.join(acronym, " ")}
        end
    end

    def findAcronyms(sentence) do
        sentence
        |> String.split
        |> Enum.filter(&isAllCaps?/1)
        |> Enum.map(&takeUntilNonAlpha/1)
        |> Enum.filter(fn(x) -> String.length(x) > 2 end)
    end

    def makeRedditPost(%{commentID: commentId, definition: definition}) do
        alreadyPosted = (Amnesia.transaction do
            Reply.where(comment_id == commentId) |> Amnesia.Selection.values
        end != [])

        #If we already replied to this comment, don't reply again!!!!
        #If it's common, don't post it all the time. 1/20 chance it will post.
        if alreadyPosted or 
        ((MapSet.member?(@commons, definition.acronym)) and not (Enum.random(1..8) == 2)) or 
        ((String.length(definition.acronym) <= 3) and not (Enum.random(1..8) == 2)) or
        MapSet.member?(@never, definition.acronym) do
            :ok
        else
            Logger.info("
            #{definition.acronym} - Definition:\n
            #{definition.meaning}\n
            Source: #{definition.link_url}\n
            Posting this to #{commentId}, btw.
            ")

            body = 
"
**#{definition.acronym}** - Definition:\n
*#{definition.meaning}*\n
[Definition origin](#{definition.link_url}) | [About](http://supercoolnameinator.reddit.com/wiki/index)
"

            Post.reply(self(), :commented, commentId, body)

            Amnesia.transaction do
                %Reply{comment_id: commentId, timestamp: unixTimestamp} |> Reply.write
            end
        end
    end

    def getRandomDefinition(acronym1) do
        selection = Amnesia.transaction do
          Acronym.where(acronym == acronym1)
        end
        definitions = Amnesia.Selection.values(selection)
        case definitions do
            [] -> nil
            _ -> Enum.random(definitions)
        end
    end
end