defmodule Sig.Broadcaster do
  def subscribe(topics) when is_list(topics), do: Enum.each(topics, &subscribe/1)
  def subscribe(topic) when is_binary(topic), do: Phoenix.PubSub.subscribe(Sig.PubSub, topic)

  def unsubscribe(topics) when is_list(topics), do: Enum.each(topics, &unsubscribe/1)
  def unsubscribe(topic) when is_binary(topic), do: Phoenix.PubSub.unsubscribe(Sig.PubSub, topic)

  def broadcast(topics, message) when is_list(topics) do
    Enum.each(topics, &broadcast(&1, message))
  end

  def broadcast(topic, message) when is_binary(topic) do
    Phoenix.PubSub.broadcast(Sig.PubSub, topic, message)
  end
end
