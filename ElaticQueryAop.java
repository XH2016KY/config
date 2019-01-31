package com.oks.aop;

import java.lang.annotation.Annotation;
import java.lang.reflect.Method;
import java.lang.reflect.Parameter;

import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.aspectj.lang.annotation.Pointcut;
import org.springframework.stereotype.Component;

import com.oks.annoation.ElasticParam;

@Component
@Aspect
public class ElaticQueryAop {

	@Pointcut(value = "execution( public * com.oks.web..*(..))")
	public void Cut() {
	};

	@Before(value = "Cut()")
	public void before(JoinPoint joinPoint) {
		StringBuilder sb = new StringBuilder();
		sb.append("{\"aggs\":{\"group_by_");
		String name = joinPoint.getSignature().getName();
		Method[] declaredMethods = joinPoint.getSignature().getDeclaringType().getDeclaredMethods();
		int e = 2;
		for (Method m : declaredMethods) {

			if (m.getName().equals(name)) {

				Parameter[] parameters = m.getParameters();
				for (Parameter p : parameters) {
					Annotation[] annotations = p.getAnnotations();
					for (Annotation a : annotations) {
						if(a instanceof ElasticParam) {
							//e++;
							sb.append(((ElasticParam) a).value()).
							append("\":{\"terms\":{\"field\":").append("\""+((ElasticParam) a).value()+"\"}},\"group_by_");
						}

					}
				}
				
			}
			//,"group_by_			
		}
		System.out.println("e="+e);
		if(e!=0) {
			sb.delete(sb.length()-11, sb.length());
			for(int k=1;k<=e;k++) {
				sb.append("}");
			}
			joinPoint.getArgs()[joinPoint.getArgs().length-1] = sb.toString();
		}
		System.out.println(sb.toString());

	}

}
