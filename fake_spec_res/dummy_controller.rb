# frozen_string_literal: true

class DummyController < ApplicationController
  def index
    render text: 'Hello'
  end
end
