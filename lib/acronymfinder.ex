defmodule Nameinator2.AcronymFinder do
  use GenServer
  require Logger
  use Amnesia
  use Database

  alias Nameinator2.Utils

  def start_link(subs) do
    GenServer.start_link(__MODULE__, subs)
  end

  def init(subs) do
      Logger.info("Initialized the acronym finder")
      # Start getting new comments every 10 seconds.

      Enum.each(subs, fn(sub)->
        Logger.info("Streaming from #{sub}")
        ElixirPlusReddit.API.Subreddit.stream_comments(self(), :comments, sub, [limit: 50], 10000)#3 * 60 * 1000)
        end
      )
      {:ok, :nostate}
  end

  def handle_info({:comments, comms}, :nostate) do
      #Jesus christ clean this thing up.
      comms.children
      |> Enum.reject(fn(x) -> x.author == "SupercoolNameinator" end)
      |> Enum.reject(fn(x) -> String.contains?(String.capitalize(x.link_title), "SERIOUS") end)
      |> Enum.map(fn (x) -> %{commentID: x.name, uses: Utils.findAcronyms(x.body)} end)
      |> Enum.filter(fn(map)->(map.uses != []) end)
      |> Enum.map(fn(map) -> %{commentID: map.commentID, definition: Utils.getRandomDefinition(hd(map.uses))} end)
      |> Enum.reject(fn(map) -> map.definition == nil end)
      |> Enum.reject(fn(map) -> Utils.isTHICC?(map.definition.meaning) end)
      |> Enum.each(&Utils.makeRedditPost/1)

      #------------------------------------------------------------------------

      acronymDefinitions = comms.children
      |> Enum.map(fn(x) -> 
        "t3_"<>linkId = x.link_id #HACK: Find a better way to get the reddit link, jesus.
        %{acronym: Utils.findAcronymDefinition(x.body), link_url: "http://reddit.com/comments/#{linkId}/_/#{x.id}"} 
      end)
      |> Enum.reject(fn(%{acronym: {acro, _}, link_url: _}) -> Utils.containsNonAlpha?(acro) end)
      |> Enum.reject(fn(%{acronym: {_, mean}, link_url: _}) -> String.ends_with?(mean, "I") end)
      |> Enum.reject(fn(%{acronym: {_, mean}, link_url: _}) -> Utils.isTHICC?(mean) end)
      |> Enum.filter(fn(%{acronym: {acro, _}, link_url: _}) -> String.length(acro) > 2 end)

      Amnesia.transaction do
        Enum.each(acronymDefinitions, fn(x)->
          %{acronym: {acro, mean}, link_url: link_url} = x
          %Acronym{acronym: acro, meaning: mean, link_url: link_url} |> Acronym.write
        end)
      end

      Logger.debug("Handled comment batch.")
      {:noreply, :nostate}
  end

  #Don't care.
  def handle_info({:commented, _}, :nostate) do
      {:noreply, :nostate}
  end
end