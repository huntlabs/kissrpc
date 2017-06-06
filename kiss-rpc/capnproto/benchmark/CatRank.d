// Copyright (c) 2013-2014 Sandstorm Development Group, Inc. and contributors
// Licensed under the MIT License:
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

module capnproto.benchmark.CatRank;

import capnproto.StructList;
import capnproto.Text;

import capnproto.benchmark.catrankschema;
import capnproto.benchmark.Common;
import capnproto.benchmark.TestCase;

void main(string[] args)
{
	auto testCase = new CatRank();
	testCase.execute(args);
}

final class CatRank : TestCase!(SearchResultList, SearchResultList, int)
{
public: //Types.
	struct ScoredResult
	{
	public:
		double score;
		SearchResult.Reader result;
	}

public: //Methods.
	override int setupRequest(SearchResultList.Builder request)
	{
		import std.array : appender;
		
		int count = fastRand(1000);
		int goodCount = 0;
		
		auto list = request.initResults(count);
		foreach(i; 0..count)
		{
			auto result = list[i];
			result.setScore(1000 - i);
			int urlSize = fastRand(100);
			
			static Text.Reader URL_PREFIX = "http://example.com";
			auto urlPrefixLength = URL_PREFIX.length;
			auto url = result.initUrl(cast(int)(urlSize + urlPrefixLength));
			auto bytes = url.asByteBuffer();
			auto bb = URL_PREFIX.asByteBuffer();
			bytes.put(bb);
			
			foreach(j; 0..urlSize)
				bytes.put(cast(byte)(97 + fastRand(26)));
			
			bool isCat = fastRand(8) == 0;
			bool isDog = fastRand(8) == 0;
			goodCount += isCat && !isDog;
			
			static snippet = appender!(char[]);
			snippet.clear();
			snippet ~= " ";
			
			int prefix = fastRand(20);
			foreach(j; 0..prefix)
				snippet ~= WORDS[fastRand(cast(uint)WORDS.length)];
			if(isCat)
				snippet ~= "cat ";
			if(isDog)
				snippet ~= "dog ";
			
			int suffix = fastRand(20);
			foreach(j; 0..suffix)
				snippet ~= WORDS[fastRand(cast(uint)WORDS.length)];
			
			result.setSnippet(cast(string)snippet.data());
		}
		
		return goodCount;
	}
	
	override void handleRequest(SearchResultList.Reader request, SearchResultList.Builder response)
	{
		import std.algorithm : sort;
		import std.array : appender;
		import std.string : indexOf;
		
		static scoredResults = appender!(ScoredResult[]);
		scoredResults.clear();
		
		foreach(result; request.getResults())
		{
			double score = result.getScore();
			auto snippet = result.getSnippet();
			if(snippet.indexOf(" cat ") != -1)
				score *= 10000;
			if(snippet.indexOf(" dog ") != -1)
				score /= 10000;
			scoredResults ~= ScoredResult(score, result);
		}
		
		scoredResults.data().sort!((a,b) => a.score > b.score);
		
		auto list = response.initResults(cast(int)scoredResults.data().length);
		foreach(i,result; scoredResults.data())
		{
			auto item = list.get(i);
			item.setScore(result.score);
			item.setUrl(result.result.getUrl());
			item.setSnippet(result.result.getSnippet());
		}
	}
	
	override bool checkResponse(SearchResultList.Reader response, int expectedGoodCount)
	{
		int goodCount = 0;
		foreach(result; response.getResults())
		{
			if(result.getScore() > 1001)
				++goodCount;
			else
				break;
		}
		return goodCount == expectedGoodCount;
	}
}
