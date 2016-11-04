#include<iostream>
#include<string>
using namespace std;

class Person {
	private:
		string name;
	public:
		unsigned int age;
		Person();
		void print_name();
		void increase_age() { age++; };
		void store_name(string input);
};

Person::Person(){
	age=0;
	name="";
};

void Person::print_name(){
	cout << name << endl;
};

void Person::store_name(string input){
	name=input;
};

int main(void){
	Person giovanni,fulano;
	giovanni.store_name("Giovanni dos Reis Nunes");
	fulano.store_name("Fulano de Tal");
	giovanni.age=43;
	giovanni.print_name();
	fulano.print_name();
	return 0;
}
