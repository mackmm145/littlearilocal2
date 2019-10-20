class PagesController < ApplicationController
  
  def home
    logger.debug "def home called"
  end

  def customer_display
    puts "customer display #" + @params[ "term_num" ]
  end

  def testpage
    @test=true
    @term_num = 1
    render 'posi_generic'
  end

  def posi1
    @test=false
    @term_num = 1
    render 'posi_generic'
  end

  def posi2
    @test=false
    @term_num = 2
    render 'posi_generic'
  end

  def terminal1
    #terminal_generic 1
    head :ok
  end

  def terminal2
    #terminal_generic 2
    head :ok
  end

private
  def posi_generic( term_num )
    @term_num = term_num
    Thread.list.each { |t| t.exit if t.thread_variable_get( :term_num ) == term_num }
    logger.debug "about to render pos_generic from def posi" + term_num.to_s
    render 'posi_generic'
  end
end