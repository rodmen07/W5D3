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

class User
    attr_reader :id, :fname, :lname
    def initialize(options)
        @id = options['id']
        @fname = options['fname']
        @lname = options['lname']
    end

    def self.find_by_id(id)
        data = QuestionsDatabase.instance.execute("SELECT * FROM users WHERE id = #{id} ")
        User.new(data[0])
    end

    def self.find_by_name(fname, lname)
        data = QuestionsDatabase.instance.execute("SELECT * FROM users WHERE fname = #{fname} AND lname = #{lname}")
        User.new(data[0])
    end

    def authored_questions
        Question.find_by_author_id(self.id)
    end

    def authored_replies
        Reply.find_by_user_id(self.id)
    end

    def followed_questions
        Question_Follows.followed_questions_for_user_id(@id)
    end

    def liked_questions
        Question_Like.liked_questions_for_user_id(@id)
    end

    def average_karma
        avg_likes = QuestionsDatabase.instance.execute("
        SELECT
            AVG()
        FROM
            questions
        LEFT OUTER JOIN
            questions_likes
        GROUP BY
            questions.user_id
        ")
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
        Question.new(data[0])
    end

    def self.find_by_author_id(author_id)
        data = QuestionsDatabase.instance.execute("SELECT * FROM questions WHERE user_id = #{author_id } ")
        data.map { |datum| Question.new(datum) }
    end

    def author
        author = QuestionsDatabase.instance.execute("SELECT * FROM users WHERE id = #{@user_id} ")
        User.new(author[0])
    end

    def replies
        Reply.find_by_user_id(@user_id)
    end

    def followers
        Question_Follows.followers_for_questions_id(@id)
    end

    def self.most_followed(n)
        Question_Follows.most_followed_questions(n)
    end

    def likers
        Question_Like.likers_for_question_id(@id)
    end

    def num_likes
        Question_Like.num_likes_for_question_id(@id)
    end

    def self.most_liked(n)
        Question_Like.most_liked_questions(n)
    end
end

class Question_Follows
    def initialize(options)
        @id = options['id']
        @question_id = options['question_id']
        @user_id = options['user_id']
    end

    def self.find_by_id(id)
        data = QuestionsDatabase.instance.execute("SELECT * FROM question_follows WHERE id = #{id} ")
        Question_Follows.new(data[0])
    end

    def self.followers_for_questions_id(question_id)
        all_users = QuestionsDatabase.instance.execute("SELECT * FROM users JOIN question_follows ON users.id = question_follows.user_id")
    end

    def self.followed_questions_for_user_id(user_id)
        all_questions = QuestionsDatabase.instance.execute("SELECT * FROM users JOIN question_follows
         ON users.id = question_follows.user_id  WHERE question_follows.user_id = #{user_id}")
    end

    def self.most_followed_questions(n)
        followed_questions = QuestionsDatabase.instance.execute("
        SELECT
            question_id, COUNT(question_id)
        FROM
            question_follows
        GROUP BY
            question_id
        ORDER BY question_id DESC
        LIMIT #{n}")
    end


end

class Reply
    def initialize(options)
        @id = options['id']
        @body= options['body']
        @question_id = options['question_id']
        @parent_reply_id = options['parent_reply_id']
        @user_id = options['user_id']
    end

    def self.find_by_id(id)
        data = QuestionsDatabase.instance.execute("SELECT * FROM replies WHERE id = #{id} ")
        Reply.new(data[0])
    end

    def self.find_by_user_id(user_id)
        data = QuestionsDatabase.instance.execute("SELECT * FROM replies WHERE user_id = #{user_id} ")
        data.map { |datum| Reply.new(datum) }
    end

    def self.find_by_question_id(question_id)
        data = QuestionsDatabase.instance.execute("SELECT * FROM replies WHERE question_id = #{question_id} ")
        data.map { |datum| Reply.new(datum) }
    end

    def author
        author = QuestionsDatabase.instance.execute("SELECT * FROM replies WHERE id = #{@user_id} ")
        Reply.new(author[0])
    end

    def question
        question = QuestionsDatabase.instance.execute("SELECT * FROM replies WHERE question_id = #{@question_id} ")
        Reply.new(question[0])
    end

    def parent_reply
        p_reply = QuestionsDatabase.instance.execute("SELECT * FROM replies WHERE question_id = #{@parent_reply_id} ")
        Reply.new(p_reply[0])
    end

    def child_replies
        c_reply = QuestionsDatabase.instance.execute("SELECT * FROM replies WHERE parent_reply_id = #{@id} ")
        c_reply.map { |datum| Reply.new(datum)}
    end
end

class Question_Like
    def initialize(options)
        @id = options['id']
        @user_id= options['user_id']
        @question_id = options['question_id']
    end

    def self.find_by_id(id)
        data = QuestionsDatabase.instance.execute("SELECT * FROM questions_likes WHERE id = #{id} ")
        Question_Like.new(data[0])
    end

    def self.likers_for_question_id(question_id)
        likers = QuestionsDatabase.instance.execute("
            SELECT *
            FROM questions_likes
            WHERE question_id = #{question_id} ")
    end

    def self.num_likes_for_question_id(question_id)
        like_count = QuestionsDatabase.instance.execute("
            SELECT COUNT(*) AS num_likes
            FROM questions_likes
            WHERE question_id = #{question_id}")
    end

    def self.liked_questions_for_user_id(user_id)
        liked_questions = QuestionsDatabase.instance.execute("
            SELECT *
            FROM questions_likes
            WHERE user_id = #{user_id} ")
    end

    def self.most_liked_questions(n)
        most_liked_questions = QuestionsDatabase.instance.execute("
        SELECT
            question_id, COUNT(question_id)
        FROM
            questions_likes
        GROUP BY
            question_id
        ORDER BY question_id DESC
        LIMIT #{n}")
    end
end



# SELECT
#     *
# FROM
# TableA
# JOIN TableB
# ON TableA.name = TableB.name
