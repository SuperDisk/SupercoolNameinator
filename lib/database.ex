use Amnesia

defdatabase Database do
    deftable Acronym, [{:id, autoincrement}, :acronym, :meaning, :link_url], type: :ordered_set, index: [:meaning] do
        @type t :: %Acronym{id: non_neg_integer, acronym: String.t, meaning: String.t, link_url: String.t}
    end

    deftable Reply, [{:id, autoincrement}, :comment_id, :timestamp], type: :ordered_set do
        @type t :: %Reply{id: non_neg_integer, comment_id: String.t, timestamp: non_neg_integer}
    end
end