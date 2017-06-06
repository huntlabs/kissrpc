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

module capnproto.benchmark.CarSales;

import capnproto.StructList;
import capnproto.Text;

import capnproto.benchmark.carsalesschema;
import capnproto.benchmark.Common;
import capnproto.benchmark.TestCase;

void main(string[] args)
{
	auto testCase = new CarSales();
	testCase.execute(args);
}

final class CarSales : TestCase!(ParkingLot, TotalValue, long)
{
public: //Methods.
	override long setupRequest(ParkingLot.Builder request)
	{
		long result = 0;
		auto cars = request.initCars(fastRand(200));
		foreach(car; cars)
		{
			randomCar(car);
			result += carValue(car.asReader());
		}
		return result;
	}
	
	override void handleRequest(ParkingLot.Reader request, TotalValue.Builder response)
	{
		long result = 0;
		foreach(car; request.getCars())
			result += carValue(car);
		response.setAmount(result);
	}
	
	override bool checkResponse(TotalValue.Reader response, long expected)
	{
		return response.getAmount() == expected;
	}

package: //Methods.
	long carValue(Car.Reader car)
	{
		long result = 0;
		result += car.getSeats() * 200;
		result += car.getDoors() * 350;
		
		foreach(wheel; car.getWheels())
		{
			result += cast(long)wheel.getDiameter() * cast(long)wheel.getDiameter();
			result += wheel.getSnowTires()? 100 : 0;
		}
		
		result += cast(long)car.getLength() * cast(long)car.getWidth() * cast(long)car.getHeight() / 50;
		
		auto engine = car.getEngine();
		result += cast(long)engine.getHorsepower() * 40;
		if(engine.getUsesElectric())
			result += engine.getUsesGas()? 5000 : 3000;
		
		result += car.getHasPowerWindows()? 100 : 0;
		result += car.getHasPowerSteering()? 200 : 0;
		result += car.getHasCruiseControl()? 400 : 0;
		result += car.getHasNavSystem()? 2000 : 0;
		
		result += cast(long)car.getCupHolders() * 25;
		
		return result;
	}
	
	void randomCar(Car.Builder car)
	{
		static string[] MAKES = [ "Toyota", "GM", "Ford", "Honda", "Tesla" ];
		static string[] MODELS = [ "Camry", "Prius", "Volt", "Accord", "Leaf", "Model S" ];
		
		car.setMake(MAKES[fastRand(cast(uint)MAKES.length)]);
		car.setModel(MODELS[fastRand(cast(uint)MODELS.length)]);
		
		car.setColor(cast(Color)fastRand(cast(uint)Color.silver + 1));
		car.setSeats(cast(ubyte)(2 + fastRand(6)));
		car.setDoors(cast(ubyte)(2 + fastRand(3)));
		
		foreach(wheel; car.initWheels(4))
		{
			wheel.setDiameter(cast(short)(25 + fastRand(15)));
			wheel.setAirPressure(cast(float)(30 + fastRandDouble(20)));
			wheel.setSnowTires(fastRand(16) == 0);
		}
		
		car.setLength(cast(short)(170 + fastRand(150)));
		car.setWidth(cast(short)(48 + fastRand(36)));
		car.setHeight(cast(short)(54 + fastRand(48)));
		car.setWeight(car.getLength() * car.getWidth() * car.getHeight() / 200);
		
		auto engine = car.initEngine();
		engine.setHorsepower(cast(short)(100 * fastRand(400)));
		engine.setCylinders(cast(byte)(4 + 2 * fastRand(3)));
		engine.setCc(800 + fastRand(10000));
		engine.setUsesGas(true);
		engine.setUsesElectric(fastRand(2) == 1);
		
		car.setFuelCapacity(cast(float)(10.0 + fastRandDouble(30.0)));
		car.setFuelLevel(cast(float)(fastRandDouble(car.getFuelCapacity())));
		car.setHasPowerWindows(fastRand(2) == 1);
		car.setHasPowerSteering(fastRand(2) == 1);
		car.setHasCruiseControl(fastRand(2) == 1);
		car.setCupHolders(cast(byte)fastRand(12));
		car.setHasNavSystem(fastRand(2) == 1);
	}
}
