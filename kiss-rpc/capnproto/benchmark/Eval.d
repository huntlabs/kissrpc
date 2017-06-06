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

module org.capnproto.benchmark.Eval;

import capnproto.StructList;
import capnproto.Text;

import capnproto.benchmark.evalschema;
import capnproto.benchmark.Common;
import capnproto.benchmark.TestCase;

void main(string[] args)
{
	auto testCase = new Eval();
	testCase.execute(args);
}

class Eval : TestCase!(Expression, EvaluationResult, int)
{
public: //Methods.
	static int makeExpression(Expression.Builder exp, int depth)
	{
		exp.setOp(operations[fastRand(Operation.modulus + 1)]);
		
		int left = 0;
		if(fastRand(8) < depth)
		{
			int tmp = fastRand(128) + 1;
			exp.getLeft().setValue(tmp);
			left = tmp;
		}
		else
			left = makeExpression(exp.getLeft().initExpression(), depth + 1);
		
		int right = 0;
		if(fastRand(8) < depth)
		{
			int tmp = fastRand(128) + 1;
			exp.getRight().setValue(tmp);
			right = tmp;
		}
		else
			right = makeExpression(exp.getRight().initExpression(), depth + 1);
		
		switch(exp.getOp())
		{
			case Operation.add:
				return left + right;
			case Operation.subtract:
				return left - right;
			case Operation.multiply:
				return left * right;
			case Operation.divide:
				return div(left, right);
			case Operation.modulus:
				return mod(left, right);
			default:
				throw new Error("impossible");
		}
	}
	
	static int evaluateExpression(Expression.Reader exp)
	{
		int left = 0, right = 0;
		
		switch(exp.getLeft().which())
		{
			case Expression.Left.Which.value:
				left = exp.getLeft().getValue();
				break;
			case Expression.Left.Which.expression:
				left = evaluateExpression(exp.getLeft().getExpression());
				break;
			default:
				break;
		}
		
		switch(exp.getRight().which())
		{
			case Expression.Right.Which.value:
				right = exp.getRight().getValue();
				break;
			case Expression.Right.Which.expression:
				right = evaluateExpression(exp.getRight().getExpression());
				break;
			default:
				break;
		}
		
		switch(exp.getOp())
		{
			case Operation.add:
				return left + right;
			case Operation.subtract:
				return left - right;
			case Operation.multiply:
				return left * right;
			case Operation.divide:
				return div(left, right);
			case Operation.modulus:
				return mod(left, right);
			default:
				throw new Error("impossible");
		}
	}
	
	override int setupRequest(Expression.Builder request)
	{
		return makeExpression(request, 0);
	}
	
	override void handleRequest(Expression.Reader request, EvaluationResult.Builder response)
	{
		response.setValue(evaluateExpression(request));
	}
	
	override bool checkResponse(EvaluationResult.Reader response, int expected)
	{
		return response.getValue() == expected;
	}

private: //Variables.
	import std.traits : EnumMembers;
	static operations = [EnumMembers!Operation];
}
