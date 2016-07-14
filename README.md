# ZZModel
Model and dictionary of mutual transformation



	NSDictionary *dict = @{
                              @"test":@[
                                      @"321321",
                                      @"test",
                                      @{@"key":@"fdfvalue"},
                                      ],
                              @"weight":@100,
                              @"size":@23123,
                              @"isFat":@1,
                              @"id" : @"20",
                              @"desciption" : @"good boy",
                              @"name" : @{
                                      @"newName" : @"lufy",
                                      @"oldName" : @"kitty",
                                      @"info" : @[
                                              @"test-data",
                                              @{@"nameChangedTime" : @"2013-08-07"}
                                              ]
                                      },
                              @"other" : @{
                                      @"bag" : @{
                                              @"name" : @"school bag",
                                              @"price" : @100.7
                                              }
                                      }
                              };
        

### dictionary -> model

        ZZStudent *stu = [ZZStudent zz_modelWithDictionary:dict];
        
        NSLog(@"dictionary -> model---weight：%f,size:%d,isFat:%d",stu.weight,stu.size,stu.isFat);
        NSLog(@"dictionary -> model---ID=%@, desc=%@, otherName=%@, oldName=%@, nowName=%@, nameChangedTime=%@", stu.ID, stu.desc, stu.otherName, stu.oldName, stu.nowName, stu.nameChangedTime);
        NSLog(@"dictionary -> model---bagName=%@, bagPrice=%f", stu.bag.name, stu.bag.price);
        
        
### model -> dictionary

        NSDictionary *stuDictionarys = [stu zz_toDictionary];
        NSLog(@"model -> dictionary---%@",stuDictionarys);
                

<br/>     
        
        
 
 		NSArray *dictArray = @[
                               @{
                                   @"name" : @"Jack",
                                   @"icon" : @"lufy.png",
                                   },
                               
                               @{
                                   @"name" : @"Rose",
                                   @"icon" : @"nami.png",
                                   }
                               ];
        
### dictionarys -> models

        NSArray *userArray = [ZZUser zz_modelsWithArray:dictArray];
        for (ZZUser *user in userArray) {
            NSLog(@"dictionarys -> models --name=%@, icon=%@", user.name, user.icon);
        }
        
### models -> dictionarys

        NSArray *dictArr = [ZZUser zz_arraryWithModels:userArray];
        NSLog(@"models -> dictionarys---%@", dictArr);
