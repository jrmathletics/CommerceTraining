using Mediachase.Commerce.Orders;
using Mediachase.Commerce.Orders.Dto;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace CommerceTraining.Models.Pages
{
    public class CheckOutViewModel
    {
        
        public CheckOutPage CurrentPage { get; set; }

        // Lab E1 - create properties below


        
        public CheckOutViewModel()
        { }

        public CheckOutViewModel(CheckOutPage currentPage)
        {
            CurrentPage = currentPage;
        }


    }
}