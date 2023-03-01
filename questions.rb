require "sqlite3"
require "singleton"

class QuestionsDatabase < SQLite3::Database
    include Singleton
    def initialize
        super('questions.db')
        self.type_translation = true
        self.results_as_hash = true
    end



end



class Question
    def initialize(options)
        @id = options['id']
        @title = options['title']
        @body = options['body']
        @user_id = options['user_id']

    end

    def self.find_by_id(id)
        
        data = QuestionsDatabase.instance.execute("SELECT * FROM questions WHERE id = #{id} ")
        data.map {|datum| Question.new(datum)}

    end


end


# CREATE TABLE questions (
#     id INTEGER PRIMARY KEY,
#     title TEXT NOT NULL,
#     body TEXT NOT NULL,
#     user_id INTEGER NOT NULL,

#     FOREIGN KEY (user_id) REFERENCES users(id)
# );

