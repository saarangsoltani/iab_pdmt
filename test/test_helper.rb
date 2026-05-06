require 'minitest/autorun'
require_relative '../lib/parser'
require_relative '../lib/models/log_entry'

class TestHelper < Minitest::Test
  def setup
    @sample_line = 'HIT|206|1772668799339|146943|461957|127.0.0.1|-|https://audio-delivery.cohostpodcasting.com/audio/example_show_id/episodes/example_episode_id/episode.mp3?v=fb6eb08ac7|IL|Podcasts/4025.400.1 CFNetwork/3860.400.51 Darwin/25.3.0|74175026932da740fb68d8856080d0f6|US'
  end
end
