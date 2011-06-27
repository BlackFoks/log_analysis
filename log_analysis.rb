﻿# coding: utf-8

# ===================
# Этот скрипт производит сравнения нового лога со старым и находит ошибки,
# отсутствующие в старом логе, но присутствующие в новом. Поиск ошибок осуществляется
# с помощью регекспов, способом идентификации ошибок выступает имя объекта, при 
# компиляции которого возникла ошибка, например HOUSE.REPAY_HOUSE или SYSTEM.IN_OPLAT.
#
# Известные проблемы:
#  * путь до файлов лога не должен включать кириллические символы
#  * Из-за отсутствия поддержки командной строкой кодировки utf-8, все выводимые 
#    данные кодируются в кодировке cp866 (IBM866), т.ч. при перенаправлении вывода 
#    в файл (> log.rb log1.txt log2.txt > output.txt) его кодировка будет cp866.
# ===================

# represents log file
class LogFile
  attr_reader :filename
  attr_reader :errors
  attr_reader :total_errors
  attr_reader :contexts
  attr_reader :linenums
  
  def initialize(filename)
    # prepare
    @filename = filename
    @errors = []
    @contexts = {}
    context = ""
    is_context = false
    @linenums = {}
    
    # read file & parse errors and context
    @file = File.open(@filename, 'r')
    @file.each do |line|
      if /\s+\d+:\s(?<err_name>.*)$/ =~ line
        # save and update context
        @contexts[@errors.last] = context
        is_context = true
        context = line
        
        # save error name
        @errors << err_name
        @linenums[err_name] = @file.lineno
      elsif is_context && !(/^\s*-+\s*$/ =~ line)
        context += line
        is_context = false
      end
    end
    @errors.uniq!
    @file.close
  end  
  
  def count_blocks
    block_started = false
    prev_block = []
    block = []
    count = 0
  
    File.open(@filename, 'r') do |file|
      file.each do |line|
        if /.*-{50,}.*/ =~ line
          #save and clear block if we found new block
          if !block_started
            prev_block = block
            block = []
            count += 1
          end
          
          block_started = !block_started       
        end
        
        if block_started
          block << line
        end        
      end
    end
    
    return count
  end
  
end

# puts line into stdout with cp866 encoding (for windows only)
def wputs(str)
  puts str.encode("cp866", str.encoding)
end

# print help
if ARGV.empty?
  wputs "Программа для сравнения логов компиляции."
  wputs "Автор: Брагин Георгий (mail@blackfoks.com), 2011\n\n"
  wputs "Использование: log.rb [опции] [старый лог] [новый лог]\n"
  exit
end

wputs "\nСравниваю файлы...\n\n"

# load logs
old_log = LogFile.new(ARGV[-2]);
new_log = LogFile.new(ARGV[-1]);

wputs "!!!!!!!!!!!!     #{old_log.count_blocks}"
wputs "!!!!!!!!!!!!     #{new_log.count_blocks}"

# get list of new errors
new_errors = new_log.errors - old_log.errors

# logs info
wputs "Старый лог: #{old_log.filename}"
wputs "Новый лог : #{new_log.filename}\n\n"

# info about errors
wputs "Ошибок в старом файле : #{old_log.errors.count}"
wputs "Ошибок в новом файле  : #{new_log.errors.count}"

# number of new errors
d_errors = old_log.errors.count - new_log.errors.count

# what's happend
if d_errors > 0
  wputs "Всего устранено ошибок: #{d_errors}"
elsif d_errors < 0
  wputs "Всего появилось ошибок: #{d_errors.abs}"
else
  wputs "Количество ошибок не изменилось"
end
puts

# puts lists
if !new_errors.empty?
  # list new errors
  wputs "Появилось новых ошибок: #{new_errors.count}\n"
  wputs "\nНовые ошибки:\n"
  new_errors.each {|err| wputs "  #{new_errors.index(err)+1}: #{err}".encode('cp866', 'cp1251') }
  
  #list errors context
  wputs "\nКонтекст ошибок:"
  new_errors.each do |err|
    wputs "\n======== Контекст ошибки ##{new_errors.index(err)+1} (строка #{new_log.linenums[err]}) ========"
    wputs new_log.contexts[err].encode('cp866', 'cp1251')
  end  
 else
  wputs "Новых ошибок не появилось."
end
