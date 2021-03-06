%%-----------------------------------------------------------------------------
%% Copyright (c) 2014, Feng Lee <feng@slimchat.io>
%% 
%% Permission is hereby granted, free of charge, to any person obtaining a copy
%% of this software and associated documentation files (the "Software"), to deal
%% in the Software without restriction, including without limitation the rights
%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%% copies of the Software, and to permit persons to whom the Software is
%% furnished to do so, subject to the following conditions:
%% 
%% The above copyright notice and this permission notice shall be included in all
%% copies or substantial portions of the Software.
%% 
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
%% SOFTWARE.
%%------------------------------------------------------------------------------

-module(emqtt_app).

-author('feng@slimchat.io').

-include("emqtt_log.hrl").

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

%%
%% @spec start(atom(), list()) -> {ok, pid()}
%%
start(_StartType, _StartArgs) ->
	print_banner(),
    {ok, Sup} = emqtt_sup:start_link(),
	start_servers(Sup),
	{ok, Listeners} = application:get_env(listen),
    emqtt:listen(Listeners),
	register(emqtt, self()),
    print_vsn(),
	{ok, Sup}.

print_banner() ->
	?PRINT("starting emqtt on node '~s'~n", [node()]).

print_vsn() ->
	{ok, Vsn} = application:get_key(vsn),
	{ok, Desc} = application:get_key(description),
	?PRINT("~s ~s is running now~n", [Desc, Vsn]).

start_servers(Sup) ->
	lists:foreach(
        fun({Name, F}) when is_function(F) ->
			?PRINT("~s is starting...", [Name]),
            F(),
			?PRINT_MSG("[done]~n");
		   ({Name, Server}) when is_atom(Server) ->
			?PRINT("~s is starting...", [Name]),
			start_child(Sup, Server),
			?PRINT_MSG("[done]~n");
           ({Name, Server, Opts}) when is_atom(Server) ->
			?PRINT("~s is starting...", [ Name]),
			start_child(Sup, Server, Opts),
			?PRINT_MSG("[done]~n")
		end,
	 	[{"emqtt cm", emqtt_cm},
         {"emqtt auth", emqtt_auth},
		 {"emqtt retained", emqtt_retained},
		 {"emqtt pubsub", emqtt_pubsub},
		 {"emqtt monitor", emqtt_monitor}
		]).

start_child(Sup, Name) ->
    {ok, _ChiId} = supervisor:start_child(Sup, worker_spec(Name)).
start_child(Sup, Name, Opts) ->
    {ok, _ChiId} = supervisor:start_child(Sup, worker_spec(Name, Opts)).

worker_spec(Name) ->
    {Name, {Name, start_link, []}, 
        permanent, 5000, worker, [Name]}.
worker_spec(Name, Opts) ->
    {Name, {Name, start_link, [Opts]}, 
        permanent, 5000, worker, [Name]}.

%%
%% @spec stop(atom) -> 'ok'
%%
stop(_State) ->
    ok.

