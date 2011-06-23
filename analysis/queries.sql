-- total number of sessions
select count(*) total_sessions from sessions;

-- number of distinct session authors
select count(distinct user_id) unique_authors from sessions;

-- total number of votes;
select count(*) total_votes from all_votes;

-- number of distinct voters
select count(distinct user_id) unique_voters from all_votes;

-- min/max number of sessions per author
select min(num_sessions), max(num_sessions) from (
select user_id, count(*) num_sessions from sessions group by user_id
) a;

-- top 10 session authors by total votes received, number of sessions, avg votes per session
select
  b.name session_author,
  sum(a.votes) total_votes,
  a.sessions,
  sum(a.votes)/a.sessions avg_votes_per_session
from
  (select
     b.user_id,
     count(*) votes,
     count(distinct b.session_id) sessions
   from
     all_votes a,
     sessions b
   where a.session_id = b.session_id
   group by 1
  ) a,
  users b
where b.user_id = a.user_id
group by 1,3
having sum(votes) > 100
order by 2 desc
limit 10;

-- top 10 voters (who place the most votes)
select a.name voter_name, count(*) votes_placed
from   users a, all_votes b
where  a.user_id = b.user_id
group by a.name
order by count(*) desc
limit 10;

-- top 10 sessions by votes
select
  count(*) total_votes, a.name session_author, b.title
from
  users a,
  sessions b,
  all_votes c
where
  a.user_id = b.user_id and
  b.session_id = c.session_id
group by session_author, title
order by total_votes desc
limit 10;

-- top 10 voters by unique session authors
select u.name voter_name, count(distinct s.user_id) unique_authors
from  sessions s 
inner join all_votes v on (v.session_id = s.session_id)
inner join users u on (v.user_id = u.user_id)
group by 1
order by unique_authors desc
limit 10;

-- number of users who only voted for sesssions by a given author
select count(*) users_voting_for_1_author from (
select u.name voter_name, count(distinct s.user_id) unique_authors, count(*) total_votes, a.name author_name
from  sessions s 
inner join all_votes v  on (v.session_id = s.session_id)
inner join users u on (v.user_id = u.user_id)
inner join users a on (s.user_id = a.user_id)
group by 1
having unique_authors = 1
order by total_votes
) a;

-- number of users who voted for every session by a given author
select count(*) voters_who_voted_for_every_session_of_an_author from (
select u.name voter_name, count(distinct s.user_id) unique_authors, count(*) total_votes, a.name author_name, count(distinct s.session_id) sessions_by_author
from  sessions s 
inner join all_votes v  on (v.session_id = s.session_id)
inner join users u on (v.user_id = u.user_id)
inner join users a on (s.user_id = a.user_id)
group by 1
) a
where unique_authors = 1 and
total_votes = sessions_by_author
;

select * from (
select u.name voter_name, count(distinct s.user_id) unique_authors, count(*) total_votes, a.name author_name, count(distinct s.session_id) sessions_by_author
from  sessions s 
inner join all_votes v  on (v.session_id = s.session_id)
inner join users u on (v.user_id = u.user_id)
inner join users a on (s.user_id = a.user_id)
group by 1
) a 
where unique_authors = 1 and total_votes != sessions_by_author
order by sessions_by_author;

-- top 10 authors receiving votes for every session by a given voter and not any other authors, number of voters, number of sessions
select author_name, sessions_by_author, count(*) distinct_voters from (
select * from (
select u.name voter_name, count(distinct s.user_id) unique_authors, count(*) total_votes, a.name author_name, count(distinct s.session_id) sessions_by_author
from  sessions s 
inner join all_votes v  on (v.session_id = s.session_id)
inner join users u on (v.user_id = u.user_id)
inner join users a on (s.user_id = a.user_id)
group by 1) a
where unique_authors = 1 and
      total_votes = sessions_by_author) b
group by 1
order by 3 desc
limit 10;

-- denormalized table
create table votes_denormalized
as
select s.session_id, s.title session_title, s.user_id author_id, s.author author_name, v.user_id voter_id, u.name voter_name
from  sessions s 
inner join all_votes v  on (v.session_id = s.session_id)
left  join users u on (v.user_id = u.user_id) -- 13 voters aren't in the users table
join users a on (s.user_id = a.user_id)
;

-- make flat file of votes_denormalized table
select * 
into  outfile 'votes_denormalized.dat'
fields terminated by ',' optionally enclosed by '"'
lines terminated by '\n'
from votes_denormalized
;

-- voters voting for less than 3 sessions
select voter_id, count(*) votes from votes_denormalized group by 1 having votes < 3;
